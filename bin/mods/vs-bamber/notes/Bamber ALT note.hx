import flixel.util.FlxAxes;

function create() {
    note.frames = Paths.getSparrowAtlas('customnotes/'+PlayState_.SONG.stage.toLowerCase(), mod);
    note.colored = !['oldfarm', 'oldfarm_night'].contains(PlayState_.SONG.stage.toLowerCase());

    note.setGraphicSize(Std.int(note.width * 0.7));
	note.updateHitbox();

    note.animation.addByPrefix('scroll', 'Phone'+note.get_appearance(), 24, true);
    note.animation.play("scroll");
}

if (!PlayState.chartTestMode) {
	function onDadHit() {
		for(d in dads) {
			if (d.animation.exists('ziiuvanPaun?')) d.playAnim('ziiuvanPaun?', true, false, 1);
		}
		PlayState.scripts.executeFunc("shake",[0.7]);
	}
	function onPlayerHit() {
		for(b in boyfriends) {
			if (b.animation.exists('ziiuvanPaun?')) b.playAnim('ziiuvanPaun?', true);
		}
		PlayState.scripts.executeFunc("shake",[0.7]);
	}
}
function updatePost(elapsed) {
	if (PlayState.SONG.song == 'Coop')
	{
		if (note.shader != null) {
			note.shader.setColors(0, 175, 8);
			note.splashColor = 0xFF00AF08;
		}
	}
}