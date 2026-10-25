import SwiftUI
import AVFoundation
import Combine

// MARK: - 歌曲資料結構
struct Song: Identifiable {
    let id = UUID()
    let name: String
    let imagename: String
    let description: String
    let albumName: String
    let releaseYear: String
    let lyrics: [String]
    let audioURL: String
}

// MARK: - 音訊播放管理器 (支援真實音樂串流與進度同步)
class AudioPlayerManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 30.0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var timer: Timer?
    
    func loadAndPlay(urlString: String, autoPlay: Bool = true) {
        stop()
        guard let url = URL(string: urlString) else { return }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // 監聽實際音訊播放進度
        let interval = CMTime(seconds: 0.2, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let itemDuration = self.player?.currentItem?.duration.seconds, !itemDuration.isNaN, itemDuration > 0 {
                self.duration = itemDuration
            }
        }
        
        // 播放完畢自動循環
        NotificationCenter.default.removeObserver(self, name: AVPlayerItem.didPlayToEndTimeNotification, object: nil)
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem, queue: .main) { [weak self] _ in
            self?.seek(to: 0)
            self?.player?.play()
        }
        
        if autoPlay {
            player?.play()
            isPlaying = true
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }
    
    func seek(to seconds: Double) {
        currentTime = seconds
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: targetTime)
    }
    
    func stop() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
    }
    
    deinit {
        stop()
    }
}

// MARK: - 主畫面 ContentView (Spotify 經典設計風格)
struct ContentView: View {
    // 4 首 back number 經典名曲與正版試聽串流
    let songs = [
        Song(
            name: "高嶺の花子さん",
            imagename: "takane",
            description: "最具代表性的單戀搖滾神曲！輕快的節奏配上腦內瘋狂妄想的歌詞，讓人既熱血又揪心。",
            albumName: "ラブストーリー",
            releaseYear: "2013",
            lyrics: [
                "君から見た僕はきっと",
                "ただのお友達なのさ",
                "会いたいんだ 今すぐその角から",
                "飛び出してきてくれないか",
                "夏の幻に抱かれて 消えてしまえ"
            ],
            audioURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/f6/b6/fe/f6b6fe11-9f5a-873b-db32-01f740bf4638/mzaf_13869072379295359407.plus.aac.p.m4a"
        ),
        Song(
            name: "水平線",
            imagename: "suiheisen",
            description: "寫給因疫情停辦全國體育大賽的高中生。溫暖撫慰人心的旋律，給予受挫者堅定向前的勇氣。",
            albumName: "ユーモア",
            releaseYear: "2021",
            lyrics: [
                "出来るだけ嘘はつかないようにしよう",
                "人の痛みがわかる人になろう",
                "歓びと悲しみの両方を",
                "抱きしめて歩いていこう",
                "水平線が光る朝に"
            ],
            audioURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/4e/08/59/4e0859ce-2631-55a7-4a1e-98eb72374fe2/mzaf_5046916400959707563.plus.aac.p.m4a"
        ),
        Song(
            name: "クリスマスソング",
            imagename: "christmas",
            description: "日劇《朝5晚9》經典主題曲！冬季王道情歌，直白傾訴在浪漫節日裡只想見心儀之人的心意。",
            albumName: "シャンデリア",
            releaseYear: "2015",
            lyrics: [
                "どこかで鐘が鳴って",
                "らしくない言葉が浮かんで",
                "会いたいと毎日思ってて",
                "それを君に知ってほしくて",
                "サンタとやらに頼んでも仕方ないよな"
            ],
            audioURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/16/d5/b0/16d5b02e-8ba2-746e-fc9c-d5c363bedf7e/mzaf_18022776085838697867.plus.aac.p.m4a"
        ),
        Song(
            name: "ハッピーエンド",
            imagename: "happyend",
            description: "電影《明天，我要和昨天的妳約會》主題曲。強顏歡笑說著告別的虐心情歌，令人動容落淚。",
            albumName: "アンコール",
            releaseYear: "2016",
            lyrics: [
                "さよならが喉の奥につっかえてしまって",
                "咳をするみたいにありがとうって言ったの",
                "次の言葉はどこかと ポケットを探しても",
                "見つかるのはあなたを好きな気持ちだけ",
                "青いまま枯れてゆく"
            ],
            audioURL: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/1a/a7/8f/1aa78fc4-fd89-f0b4-1668-6861a97c8525/mzaf_9238533174777607970.plus.aac.p.m4a"
        )
    ]
    
    // 狀態管理
    @State private var currentIndex = 0
    @State private var isLiked = false
    @State private var isShuffleActive = false
    @State private var isRepeatActive = true
    @State private var isDraggingSlider = false
    @State private var dragSliderValue: Double = 0
    
    @StateObject private var audioManager = AudioPlayerManager()
    
    // Spotify 經典品牌配色
    let spotifyGreen = Color(red: 29/255, green: 185/255, blue: 84/255)
    let spotifyDarkBg = Color(red: 18/255, green: 18/255, blue: 18/255)
    
    var currentSong: Song {
        songs[currentIndex]
    }
    
    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > 720
            
            ZStack {
                // 背景：當前專輯封面放大並高斯模糊，打造 Spotify 氛圍光影
                Image(currentSong.imagename)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .blur(radius: 65)
                    .opacity(0.38)
                    .ignoresSafeArea()
                
                // Spotify 深黑暗角遮罩
                spotifyDarkBg.opacity(0.85)
                    .ignoresSafeArea()
                
                // 主要介面佈局
                VStack(spacing: 0) {
                    // 頂部導航標題列
                    topHeaderView
                    
                    if isWide {
                        // 桌面寬螢幕模式：左邊播放器，右邊即時歌詞與賞析
                        HStack(alignment: .top, spacing: 48) {
                            playerSection
                                .frame(maxWidth: 420)
                            
                            lyricsAndAboutSection
                                .frame(maxWidth: 500)
                        }
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                    } else {
                        // 直式 / 緊湊模式
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                playerSection
                                    .frame(maxWidth: 380)
                                
                                lyricsAndAboutSection
                                    .frame(maxWidth: 380)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // 底部播放設備狀態指示
                    bottomDeviceBar
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 初始化載入第一首歌
            audioManager.loadAndPlay(urlString: currentSong.audioURL, autoPlay: false)
        }
    }
    
    // MARK: - 頂部標題列
    var topHeaderView: some View {
        HStack {
            Image(systemName: "chevron.down")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("正在播放的樂團")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                
                Text("back number 代表作名曲")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - 播放器主區塊（封面、歌名、進度條、控制按鈕）
    var playerSection: some View {
        VStack(spacing: 20) {
            // 封面圖片
            Image(currentSong.imagename)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.65), radius: 24, x: 0, y: 14)
                .animation(.easeInOut(duration: 0.35), value: currentIndex)
            
            // 歌名、藝人名與收藏愛心
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentSong.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("back number • \(currentSong.albumName)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isLiked ? spotifyGreen : .white.opacity(0.7))
                        .scaleEffect(isLiked ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
            }
            
            // Spotify 經典風格音樂進度條
            VStack(spacing: 6) {
                GeometryReader { geo in
                    let progress = audioManager.duration > 0 ? (isDraggingSlider ? dragSliderValue : (audioManager.currentTime / audioManager.duration)) : 0
                    
                    ZStack(alignment: .leading) {
                        // 底軌
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)
                        
                        // 進度軌
                        Capsule()
                            .fill(spotifyGreen)
                            .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: 4)
                        
                        // 拖曳小圓點
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .offset(x: max(0, min(geo.size.width * CGFloat(progress) - 6, geo.size.width - 12)))
                    }
                    .frame(height: 12)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDraggingSlider = true
                                let clamped = max(0, min(value.location.x / geo.size.width, 1))
                                dragSliderValue = Double(clamped)
                            }
                            .onEnded { value in
                                let clamped = max(0, min(value.location.x / geo.size.width, 1))
                                let targetSec = Double(clamped) * audioManager.duration
                                audioManager.seek(to: targetSec)
                                isDraggingSlider = false
                            }
                    )
                }
                .frame(height: 12)
                
                // 時間指示
                HStack {
                    Text(formatTime(isDraggingSlider ? dragSliderValue * audioManager.duration : audioManager.currentTime))
                    Spacer()
                    Text(formatTime(audioManager.duration))
                }
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.6))
            }
            
            // Spotify 播放控制面板
            HStack(spacing: 0) {
                // 1. 隨機按鈕 (shuffle) - while 迴圈確保不重複
                Button(action: {
                    isShuffleActive.toggle()
                    var randomIndex = currentIndex
                    while randomIndex == currentIndex {
                        randomIndex = Int.random(in: 0..<songs.count)
                    }
                    changeSong(to: randomIndex)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20))
                            .foregroundColor(isShuffleActive ? spotifyGreen : .white.opacity(0.7))
                        
                        Circle()
                            .fill(isShuffleActive ? spotifyGreen : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 2. 上一首按鈕 (backward.fill) - 循環切換
                Button(action: {
                    let nextIndex = (currentIndex > 0) ? (currentIndex - 1) : (songs.count - 1)
                    changeSong(to: nextIndex)
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 3. 播放 / 暫停 大圓形按鈕
                Button(action: {
                    audioManager.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.black)
                            .offset(x: audioManager.isPlaying ? 0 : 2)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 4. 下一首按鈕 (forward.fill) - 循環切換
                Button(action: {
                    let nextIndex = (currentIndex < songs.count - 1) ? (currentIndex + 1) : 0
                    changeSong(to: nextIndex)
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 5. 循環按鈕 (repeat)
                Button(action: {
                    isRepeatActive.toggle()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 20))
                            .foregroundColor(isRepeatActive ? spotifyGreen : .white.opacity(0.7))
                        
                        Circle()
                            .fill(isRepeatActive ? spotifyGreen : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Spotify 經典「歌詞卡片」與「歌曲介紹」區塊
    var lyricsAndAboutSection: some View {
        VStack(spacing: 16) {
            // 歌詞卡片 (Lyrics Card)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("歌詞")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("即時滾動")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(currentSong.lyrics.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(index == activeLyricIndex ? .white : .white.opacity(0.35))
                            .scaleEffect(index == activeLyricIndex ? 1.03 : 1.0, anchor: .leading)
                            .animation(.spring(response: 0.3), value: activeLyricIndex)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08))
            .cornerRadius(16)
            
            // 歌曲深度解說卡片 (About the track)
            VStack(alignment: .leading, spacing: 8) {
                Text("名曲賞析 • back number")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(spotifyGreen)
                    .textCase(.uppercase)
                
                Text(currentSong.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(4)
                
                HStack {
                    Text("發行年份：\(currentSong.releaseYear)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Text("第 \(currentIndex + 1) / \(songs.count) 首")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
        }
    }
    
    // MARK: - 底部裝置狀態欄
    var bottomDeviceBar: some View {
        HStack {
            Image(systemName: "hifispeaker.fill")
                .foregroundColor(spotifyGreen)
                .font(.footnote)
            
            Text("正在此裝置上播放 (Spotify Connect 風格)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(spotifyGreen)
            
            Spacer()
            
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.4))
    }
    
    // MARK: - 輔助方法
    
    // 計算當前高亮歌詞行數
    var activeLyricIndex: Int {
        guard audioManager.duration > 0, !currentSong.lyrics.isEmpty else { return 0 }
        let progress = audioManager.currentTime / audioManager.duration
        let idx = Int(progress * Double(currentSong.lyrics.count))
        return min(idx, currentSong.lyrics.count - 1)
    }
    
    // 切換歌曲邏輯
    func changeSong(to newIndex: Int) {
        currentIndex = newIndex
        audioManager.loadAndPlay(urlString: currentSong.audioURL, autoPlay: true)
    }
    
    // 時間格式化 (00:00)
    func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(max(0, seconds))
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        return String(format: "%d:%02d", min, sec)
    }
}

#Preview {
    ContentView()
}
