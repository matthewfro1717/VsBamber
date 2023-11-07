import Note;
import flixel.math.FlxPoint;
import flixel.text.FlxTextBorderStyle;
import ScoreText;
import flixel.util.FlxAxes;
import flixel.ui.FlxBar;
import Main;
import openfl.text.TextFormat;
import Settings;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxVelocity;

engineSettings.scoreTextSize = 20;
engineSettings.animateMsLabel = engineSettings.showPressDelay = engineSettings.showRating = engineSettings.alphabetOutline = engineSettings.showRatingTotal = engineSettings.watermark = engineSettings.smoothHealthbar = false;

var fakeScoreText; //To simulate the changes in score.

var newTimerBar;
PlayState.set_isWidescreen(false);

var rankingTexts = [
	['You Suck!', 0.2], //From 0% to 19%
	['Good grief...', 0.4], //From 20% to 39%
	['Seriously?', 0.5], //From 40% to 49%
	['Mid', 0.6], //From 50% to 59%
	['Meh', 0.69], //From 60% to 68%
	['Nice', 0.7], //69%
	['Good', 0.8], //From 70% to 79%
	['Awesome', 0.9], //From 80% to 89%
	['Bambtastic!', 1], //From 90% to 99%
	['Perfect!!', 1], //100%
];

function create() {
	Settings.engineSettings.data.fps_showMemoryPeak = false;

	FlxG.stage.window.onClose.add(destroy);
}

function destroy() {
	Settings.engineSettings.data.fps_showMemoryPeak = engineSettings.fps_showMemoryPeak;
	FlxG.save.flush();

	FlxG.stage.window.onClose.remove(destroy); //Cleanup
}

function createPost() {
    PlayState.scripts.executeFunc('setCamType', ['classic']);

	fakeScoreText = new FlxText(healthBar.x + (healthBar.width * 0.28), 0, guiSize.x, "A", 20);
	fakeScoreText.setFormat(Paths.font("vcr_osd.ttf"), Std.int(engineSettings.scoreTextSize), 0xFFFFFFFF, 'center', FlxTextBorderStyle.OUTLINE, 0xFF000000);
	fakeScoreText.borderSize = 1.5;
	fakeScoreText.cameras = [camHUD];
	fakeScoreText.screenCenter();
	fakeScoreText.y = healthBarBG.y + (engineSettings.downscroll ? 60 : 30);
	add(fakeScoreText);
	fakeScoreText.alpha = 0;
	FlxTween.tween(fakeScoreText, {alpha: 1}, 0.75, {ease: FlxEase.quartInOut});
	fakeScoreText.text = 'Score: ' + songScore + (engineSettings.showMisses ? ' | Misses: ' + misses : '') + (engineSettings.showAccuracy ? ' | Rating: ?' : '');

	scoreText.visible = false;

	if (engineSettings.middleScroll) {
		for (i in 0...cpuStrums.length) {
			PlayState.getStrum(i).x = (guiSize.x / 4) - (PlayState.SONG.keyNumber / 2 * Note.swagWidth) + (Note.swagWidth * i);
			PlayState.getStrum(i).visible = true;
			PlayState.getStrum(i).notes_alpha = PlayState.getStrum(i).alpha = 0.5;

			if (i > 1) {
				PlayState.getStrum(i).x += guiSize.x / 2 + 25;
			}
		}
	}

	if (engineSettings.showTimer) {
		timerFinal.visible = false;
		timerBG.visible = false;
		timerBar.visible = false;

		if (engineSettings.timerSongName) timerNow.visible = false;

		(engineSettings.timerSongName ? timerText : timerNow).size = 24;
		(engineSettings.timerSongName ? timerText : timerNow).borderSize = 2;
		(engineSettings.timerSongName ? timerText : timerNow).visible = false;


		newTimerBar = new FlxBar(timerBG.x + 4, timerBG.y + 4, 'LEFT_TO_RIGHT', Std.int(timerBG.width - 8), Std.int(timerBG.height - 8));
		if (!engineSettings.downscroll) newTimerBar.y += timerBG.height - 4;
		newTimerBar.cameras = [camHUD];
		newTimerBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		newTimerBar.alpha = 0;
		newTimerBar.visible = false;
		insert(members.indexOf(timerBG), newTimerBar);
	}
}

function postCreate() {
	Main.fps.defaultTextFormat = new TextFormat(Paths.font('_sans'), 14, Main.fps.color);
}

function musicstart() {
	if (timerText != null) {
		newTimerBar.setParent(Conductor, "songPosition");
		newTimerBar.setRange(0, Math.max(inst.length, 1000));

		newTimerBar.visible = true;
		FlxTween.tween(newTimerBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		(engineSettings.timerSongName ? timerText : timerNow).alpha = 0;
		(engineSettings.timerSongName ? timerText : timerNow).visible = true;
		FlxTween.tween((engineSettings.timerSongName ? timerText : timerNow), {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		timerBG.alpha = 0;
		timerBG.visible = true;
		FlxTween.tween(timerBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
	}
}

function updatePost(elapsed) {
	scoreWarning.y = strumLine.y + strumLineNotes.members[0].height/2 - scoreWarning.height/2;

	if (engineSettings.showTimer && !engineSettings.timerSongName) { 
		timerText.alpha = 0;
		timerNow.screenCenter(FlxAxes.X);
	}
}

var accuracyText = '?';
function miss() {
	if (!engineSettings.botplay) calculateRating();
	fakeScoreText.text = 'Score: ' + songScore + (engineSettings.showMisses ? ' | Misses: ' + misses : '') + (engineSettings.showAccuracy ? ' | Rating: ' + accuracyText : '');
}

var scoreTxtTween;
function onPlayerHit(note) {
	if (!engineSettings.botplay) { 
		calculateRating();
		if(engineSettings.animateInfoBar) {
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			fakeScoreText.scale.x = 1.075;
			fakeScoreText.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(fakeScoreText.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
	}
	fakeScoreText.text = 'Score: ' + songScore + (engineSettings.showMisses ? ' | Misses: ' + misses : '') + (engineSettings.showAccuracy ? ' | Rating: ' + accuracyText : '');
}

function calculateRating() {
	var ratingName = '';

	if (PlayState.get_accuracy_() >= 1) ratingName = rankingTexts[rankingTexts.length - 1][0];
	else {
		for (i in 0...rankingTexts.length-1)
		{
			if(PlayState.get_accuracy_() < rankingTexts[i][1])
			{
				ratingName = rankingTexts[i][0];
				break;
			}
		}
	}

	var advancedRating = "";
    if (numberOfArrowNotes > 0) {
        if (misses == 0) {
            var t = "FC";
            for (r in ratings) {
                if (hits[r.name] > 0 && r.fcRating != null) {
                    t = r.fcRating;
                    }
                }
            advancedRating = t;
        }
    	else if (misses < 10) advancedRating = "SDCB"
		else if (numberOfArrowNotes > 0) advancedRating = "Clear";
    }


	accuracyText = ratingName + ' (' + (Math.floor(PlayState.get_accuracy_() * 10000) / 100) + '%) - ' + advancedRating;
}

var comboPath = 'HUD/funkin/';
function onShowCombo(combo:Int, coolText:FlxText) {
	coolText.x = guiSize.x * 0.35;
	var tweens:Array<VarTween> = [];

	var rating:FlxSprite = new FlxSprite();
	rating.loadGraphic(Paths.image(comboPath+lastRating.name));
	rating.x = coolText.x - 40;
	rating.y = coolText.y - 60;
	rating.acceleration.y = 550;
	rating.velocity.y -= FlxG.random.int(140, 175);
	rating.velocity.x -= FlxG.random.int(0, 10);
	rating.antialiasing = lastRating.antialiasing;
	rating.cameras = [camHUD];
	rating.setGraphicSize(Std.int(rating.width * 0.7));
	rating.updateHitbox();
	add(rating);

	var seperatedScore:Array<Int> = [];
	var stringCombo = Std.string(combo);
	for (i in 0...stringCombo.length)
	{
		seperatedScore.push(Std.parseInt(stringCombo.charAt(i)));
	}

	while (seperatedScore.length < 3)
		seperatedScore.insert(0, 0);

	var daLoop:Int = 0;
	var comboColor = boyfriend.getColors()[0];
	for (i in seperatedScore)
	{
		var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(comboPath + Std.int(i)));
		numScore.x = coolText.x + (43 * daLoop) - 90;
		numScore.y = coolText.y + 80;

		numScore.acceleration.y = FlxG.random.int(200, 300);
		numScore.velocity.y -= FlxG.random.int(140, 160);
		numScore.velocity.x = FlxG.random.float(-5, 5);

		numScore.setGraphicSize(Std.int(numScore.width * 0.5));
		numScore.updateHitbox();
		numScore.cameras = [camHUD];

		add(numScore);

		tweens.push(FlxTween.tween(numScore, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				numScore.destroy();
			},
			startDelay: Conductor.crochet * 0.002
		}));

		daLoop++;
	}

	tweens.push(FlxTween.tween(rating, {alpha: 0}, 0.2, {
		onComplete: function(tween:FlxTween)
		{
			rating.destroy();
		},
		startDelay: Conductor.crochet * 0.001
	}));

	if (engineSettings.maxRatingsAllowed > -1) optimizedTweenSet.push(tweens);

	return false;
}

var thineCreditObjects = [];

var lastTime = 0;
var activateCreaits = false;
function creditUpdate(songBG, songTitle, creditTexts, creditIcons, elapsed) {
	if (activateCreaits) {
		lastTime += elapsed;
		songBG.shader.data.uTime.value = [lastTime];

		for (catText in creditTexts) {
			for (i in catText) {
				i.updateMotion(elapsed); //for some reason you have to call it
			}
		}
	}
}

function creditIconBehavior(songIcons, songTexts, elapsed) {
	for (catText in songIcons) {
		for (icon in catText) {
			if (icon != null) {
				var decBeat = curDecBeat;
				if (decBeat < 0)
					decBeat = 1 + (decBeat % 1);
						
				var iconlerp = FlxMath.lerp(songTexts[0][1].height * 2 * 1.3, songTexts[0][1].height * 2, FlxEase.cubeOut(decBeat % 1));
				icon.setGraphicSize(iconlerp);
			}
		}
	}

	return false;
}

function creditSetup(songBG, songTitle, creditTexts, creditIcons) {
	songBG.screenCenter();
	songBG.shader = new CustomShader(Paths.shader('textureoffset'));
	songBG.shader.data.speed.value = [0.255];
	songBG.alpha = 0;
	remove(songBG); insert(PlayState.members.indexOf(strumLineNotes), songBG);

	songTitle.screenCenter();
	songTitle.x += 500;
	songTitle.y -= 50;
	songTitle.angle = 0;
	remove(songTitle); insert(PlayState.members.indexOf(strumLineNotes), songTitle);

	songTitle.x -= guiSize.x;

	var lastIndex = [-1,0];
	
	for (catText in creditTexts) {
		for (i in catText) {
			i.screenCenter();
			i.angle = 0;

			if (catText.indexOf(i) == 0) i.y += FlxG.random.float(-60, 60);
			else {
				i.y = catText[0].y + catText[0].height/2 - i.height/2;
			}
			
			i.x = (lastIndex[0] == -1 ? songTitle.x : creditTexts[lastIndex[0]][lastIndex[1]].x) - i.width - 20;

			if (catText.indexOf(i) == 0 && creditTexts.indexOf(catText) != 0) i.x -= 50;

			lastIndex[1]++;

			if (lastIndex[0] == -1) {
				lastIndex = [0, 0];
			}

			if (lastIndex[1] > creditTexts[lastIndex[0]].length - 1) {
				lastIndex[1] = 0;
				lastIndex[0]++;
			}

			remove(i); insert(PlayState.members.indexOf(strumLineNotes), i);
		}
	}

	for (catIcon in creditIcons) {
		for (i in catIcon) {
			i.angle = 0;

			var targetCredit = creditTexts[creditIcons.indexOf(catIcon)][catIcon.indexOf(i) + 1];
			i.x = targetCredit.x + targetCredit.width/2 - i.width/2;
			i.y = targetCredit.y + targetCredit.height/2 - i.height/2 + (i.height + 20) * (targetCredit.y + targetCredit.height/2 > songBG.y + songBG.height/2 ? -1 : 1);
			remove(i); insert(PlayState.members.indexOf(strumLineNotes), i);
		}
	}
}


function creditBehavior(songBG, songTitle, songTexts, songIcons, songTweens) {
	songTweens.push(FlxTween.tween(songBG, {alpha: 0.6}, 1, {ease: FlxEase.quartOut}));
	activateCreaits = true;
    PlayState.scripts.setVariable('creditTweens', songTweens);

	songTitle.velocity.x = 450;

	for (catIcon in songTexts) {
		for (i in catIcon) {
			i.initMotionVars();
			i.velocity.x = 450;
		}
	}

	for (catIcon in songIcons) {
		for (i in catIcon) {
			i.velocity.x = 450;
		}
	}

	return 8;
}

function creditEnding(songBG, songTitle, songTexts, songIcons, songTweens) {
	songTitle.destroy();

	for (acc in [songTexts, songIcons]) {
		for (cat in acc) {
			for (i in cat) {
				i.destroy();
			}
		}
	}
	PlayState.scripts.setVariable('songTexts', []);
	PlayState.scripts.setVariable('songIcons', []);

	songTweens.push(FlxTween.tween(songBG, {alpha: 0}, 1, {ease: FlxEase.quartIn, onComplete: function(tween:FlxTween) {
		activateCreaits = false;
		PlayState.scripts.executeFunc('creditsDestroy');
	}}));
    PlayState.scripts.setVariable('creditTweens', songTweens);
}