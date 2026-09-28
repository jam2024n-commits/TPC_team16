extends AudioStreamPlayer

# BGM を流す（Autoload: Bgm）。各シーンの _ready で play_music / stop_music を呼ぶ。
# いま流れている曲と同じ曲を頼まれたときは最初からにしない（層のやり直しや次の層へ進んでも途切れない）。
# ループは各曲のインポート設定（loop=true）で行う

const VOLUME_DB := -6.0


func _ready() -> void:
	# アイテム獲得の演出などでゲームを止めている間も流し続ける
	process_mode = Node.PROCESS_MODE_ALWAYS
	volume_db = VOLUME_DB


func play_music(music: AudioStream) -> void:
	if stream == music and playing:
		return
	stream = music
	play()


func stop_music() -> void:
	stop()
	stream = null
