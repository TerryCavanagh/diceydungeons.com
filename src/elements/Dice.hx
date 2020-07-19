package elements;

import states.*;
import haxegon.*;
import displayobjects.DiceGraphic;
import displayobjects.GamepadButtonImage;
import lime.ui.GamepadButton;
import motion.Actuate;
import motion.easing.Expo;
import openfl.geom.Point;

class Dice{
	public function new(_x:Float = 0, _y:Float = 0){
		justgrabbed = false;
		grabbed = false;
		released = false;
		touch = null;
		aiassigned = null;
		
		basevalue = 1;
		modifier = 0;
		assigned = null;
		temporary = false;
		locked = false;
		priority = false;
		frozen = false;
		burn = false;
		alternateburn = false;
		consumed = false;
		inlerp = false;
		dicecol = Col.WHITE;
		hasmotion = false;
		animation = [];
		owner = null;
		blind = false;
		ignitedthisturn = false;
		
		x = _x;
		y = _y;

		startdraggingposition = new Point();
		startdraggingposition_local = new Point();

		targetx = _x;
		targety = _y;
		
		shakex = 0;
		shakey = 0;
		
	  showoverlayimage = false;
	  overlayimage = "";
		overlayimage_xoff = 0;
		overlayimage_yoff = 0;
		overlayimage_alpha = 1;
		overlayimage_animate = 0;
		overlayimage_animatetime = 0;
		overlayimage_frame = 0;
		overlayimage_repeat = false;
		
		vx = 0;
		vy = 0;
		ax = 0;
		ay = 0;
		flash = 0;

		canbedragged = true;
		
		graphic = new DiceGraphic(basevalue);
	}
	
	public function remove(){
		graphic.remove();
	}
	
	public function dispose(){
		graphic.dispose();
	}
	
	public function copyfrom(otherdice:Dice){
		temporary = otherdice.temporary;
		basevalue = otherdice.basevalue;
		modifier = otherdice.modifier;
		blind = otherdice.blind;
	}
	
	public function animateremovedice(fromdir:Int){
		if (fromdir == Gfx.BOTTOM){
			fromdir = Screen.height + 40 * 6;
		}else{
			fromdir = -40 * 6;
		}

		inlerp = true;
		Actuate.tween(this, 0.5 / BuildConfig.speed, { y: fromdir })
			.onComplete(function(){
				this.inlerp = false;
				this.consumed = true;
				this.dicealpha = 0;
				if (showoverlayimage) {
					//trace("removing overlay image on dice");
					showoverlayimage = false;
					burn = false;
					alternateburn = false;
					overlayimage_alpha = 0;
					graphic.overlayimage.remove();
				}
			});
	}
	
	public function removedice(fromdir:Int, _delay:Float){
		if (fromdir == Gfx.BOTTOM){
			fromdir = Screen.height + 40 * 6;
		}else{
			fromdir = -40 * 6;
		}
		
		inlerp = true;
		Actuate.tween(this, 0.5 / BuildConfig.speed, { y: fromdir })
			.delay(_delay / BuildConfig.speed)
			.onComplete(function(oldy:Int){
				inlerp = false;
				consumenow();
			}, [y]);
	}
	
	public function animatereroll(newvalue:Int, fromdir:Int, _delay:Float = 0){
		if (fromdir == Gfx.BOTTOM){
			fromdir = Screen.height + 40 * 6;
		}else{
			fromdir = -40 * 6;
		}
		
		if (newvalue < 0) newvalue = 1;
		if (newvalue > 6) newvalue = 6;
		
		inlerp = true;
		Actuate.tween(this, 0.5 / BuildConfig.speed, { y: fromdir })
			.delay(_delay / BuildConfig.speed)
			.onComplete(function(oldy:Int){
				this.basevalue = newvalue;
				Actuate.tween(this, 0.5 / BuildConfig.speed, { y: oldy })
					.onComplete(function() {
						inlerp = false;
					});
			}, [y]);
	}
	
	public function intween():Bool{
		return Game.intween(this);
	}
	
	public function available():Bool{
		if (assigned == null && !locked && !consumed){
			return true;
		}
		return false;
	}

	public function availableorlocked():Bool{
		if (assigned == null && !consumed){
			return true;
		}
		return false;
	}
	
	public function roll(f:Fighter){
		if (Rules.modifyenemydicerange){
			if (!f.isplayer){
				basevalue = Random.pick(Rules.actualenemydicerange);
			}else{
				basevalue = Random.int(1, 6);
			}
		}else if (Rules.modifyplayerdicerange){
			if (f.isplayer){
				basevalue = Random.pick(Rules.actualplayerdicerange);
			}else{
				basevalue = Random.int(1, 6);
			}
		}else{
			basevalue = Random.int(1, 6);
		}
		//Should never kick in, but just in case...
		if (basevalue < 1) basevalue = 1;
		if (basevalue > 6) basevalue = 6;
	}
	
	public function kick(dir:Float, speed:Float){
		hasmotion = true;
		ax = Geom.cos(dir) * speed;
		ay = Geom.sin(dir) * speed;
	}
	
	public function updateoverlay(){
		if (showoverlayimage){
			if (overlayimage_animate > 0){
				overlayimage_animatetime -= Game.deltatime;
				if (overlayimage_animatetime <= 0){
					overlayimage_animatetime = overlayimage_animate;
					if(overlayimage_repeat){
						overlayimage_frame = (overlayimage_frame + 1) % graphic.overlayimage.totalframes;
					}else{
						overlayimage_frame = overlayimage_frame + 1;
						if (overlayimage_frame >= graphic.overlayimage.totalframes){
							showoverlayimage = false;
							graphic.overlayimage.remove();
						}
					}
				}
			}
		}
	}

	public function applyburntoowner(){
		if (burn) {
			burn = false;
			showoverlayimage = false;
			graphic.overlayimage.remove();
			graphic.burntext.remove();
			//Do the burn!
			Script.actionexecute(Script.load("attack(" + Rules.burningdicecost + ", FIRE);"), owner, owner, 0, null, null, null);
			AudioControl.play("pickupburningdice");
		}
	}
	
	public function istargetting(e:Equipment):Bool{
		//Is the enemy planning to use this dice on this equipment?
		//(but hasn't *yet* assigned it to anything)
		if (aiassigned == e){
			if (assigned == null) return true;
		}
		
		if(Combat.turn == "player"){		
			//Is this dice physically held over the equipment?
			if (Geom.inbox(x + 121, y + 121, e.x, e.y, e.width, e.height)){
				return true;
			}
			
			//Are we targetting the equipment with this dice using the gamepad?
			if (Combat.gamepadshowdicehighlight(this)){
				if (Combat.gamepad_selectedequipment == e)	return true;
			}
		}
		
		return false;
	}
	
	public function update(dicesize:Int = 242){
		this.dicesize = dicesize;
		
		if (dicealpha <= 0) return;
		
		dicecol = 0xDDDDDD;
		
		if (flash > 0){
			flash -= Game.deltatime;
			if (flash < 0) flash = 0;
		}
		
		updateoverlay();
		
		var cangrab:Bool = canbedragged;
		
		if (Combat.turn != "player") cangrab = false;
		if (locked){
			//Keep this logic seperate from the general MultiTouch logic for simplicity
			//TO DO MULTITOUCH: Check that locked dice work correctly with touch controls
			if (MultiTouch.hover(x, y, dicesize, dicesize)){
				if (MultiTouch.hovertouch.click() && shakex == 0 && shakey == 0){
					shakex = Random.int( -4 * 6, 4 * 6);
					shakey = Random.int( -4 * 6, 4 * 6);
					Actuate.tween(this, 0.08 / BuildConfig.speed, { shakex: 0, shakey: 0 });
					AudioControl.play("_lock");
				}
			}
			cangrab = false;
		}
		if (frozen) cangrab = false;
		if (consumed) cangrab = false;
		if (Combat.selectspellslotmode) cangrab = false;
		if (assigned != null){
			if (!assigned.ready){
				cangrab = false;
			}
		}
		
		//This dice can be grabbed
		if (cangrab){
			if (touch == null){ //It isn't grabbed by anything yet
				//Loop through all the individual touches on the screen right now
				for (t in MultiTouch.touches){
					//This touch is hovering over and touching this dice
					if (t.inbox(x, y, dicesize, dicesize) && t.held()){
						//Is this dice already being grabbed by another touch?
						if (t.associateddice == null){
							//Finally, only pick up dice on a "click" action, not by dragging
							if (t.click()){
								touch = t;
								touch.setdice(this);
								grabbed = true;
								released = false;
								justgrabbed = true;
								break;
							}
						}
					}
				}
			}else{
				//Is it already being grabbed?
				if (grabbed){
					if (touch.held()){
						//We're still holding it
						grabbed = true;
						released = false;
						justgrabbed = false;
					}else{
						//It's been released!
						justgrabbed = false;
						grabbed = false;
						released = true;
						touch = null;
					}
				}
			}
		}else{
			//This dice can't be grabbed. If it currently has a touch, release it now.
			if (touch != null){
				grabbed = false;
				released = true;
				touch = null;
			}
		}
		
		if (justgrabbed){
			startdraggingposition.setTo(touch.x, touch.y);
			startdraggingposition_local.setTo(touch.x - x, touch.y - y);
			
			if (burn){
				applyburntoowner();
			}else{
				if (blind){
					AudioControl.play("pickupblinddice");
				}else{
					AudioControl.play("pickupdice");
				}
			}
			
			justgrabbed = false;
		}
		
		if (grabbed){
			if(intween()) {
				Actuate.stop(this);
			}
			
			if (assigned != null){
				if (Game.diceslotissparedice(assigned.slots[assignedposition])){
					var oldassigned:Equipment = assigned;
					assigned.ready = true;
					assigned.removedice(this);
					Combat.useequipmentifready(oldassigned, Game.player, Game.monster, 1);
				}
			}
		}
		
		if (grabbed){
			// recheck burn here so the player get burned if they catch the dice before the burn effect has been applied
			if (burn)	applyburntoowner();
			
			// If the dice we've grabbed is already in a slot (i.e. multislot equipment), unassign it
			if (touch != null){
				if(touch.associateddice == this){
					if (touch.deltax != 0 && touch.deltay != 0){
						if (touch.associateddice.assigned != null){
							//Remove the dice from this equipment
							touch.associateddice.assigned.removedice(this);
						}
					}
				}
			}
			
			if (touch != null){
				x = touch.x - startdraggingposition_local.x;
				y = touch.y - startdraggingposition_local.y;
			}
			x = Geom.clamp(x, -120, Screen.width - 120);
			y = Geom.clamp(y, -120, Screen.height - 120);
		}else{
			if(hasmotion){
				vx += ax;
				vy += ay;
				if (ax > 1){      	ax--;
				}else if (ax < -1){	ax++;
				}else{      				ax = 0;
				}
				if (ay > 1){      	ay--;
				}else if (ay < -1){	ay++;
				}else{      				ay = 0;
				}
				
				vx = vx * 0.6;
				if (Math.abs(vx) < 0.05) vx = 0;
				
				vy = vy * 0.6;
				if (Math.abs(vy) < 0.05) vy = 0;
				
				x += vx;
				y += vy;
				
				if (vx == 0 && vy == 0){
					hasmotion = false;
				}
			}
		}
		
		if (assigned != null){
			//Move the dice to the assigned spot (for card movement)
			if (!inlerp){
				if (assigned.skillcard == "witch"){
					//Make an exception for the witch skillcard: we want to be able to drop dice anywhere on it
				}else{
					if (assigned.shockedsetting > 0){
						#if html5
						if (assignedposition != null){
						#end
						x = assigned.x + assigned.shocked_slotpositions[assignedposition].x + Game.dicexoffset;
						y = assigned.y + assigned.shocked_slotpositions[assignedposition].y + Game.diceyoffset;
						#if html5
						}
						#end
					}else{
						#if html5
						if (assignedposition != null){
						#end
							x = assigned.x + assigned.slotpositions[assignedposition].x + assigned.slotshake[assignedposition].x + Game.dicexoffset;
							y = assigned.y + assigned.slotpositions[assignedposition].y + assigned.slotshake[assignedposition].y + Game.diceyoffset;
						#if html5
						}
						#end
					}
				}
			}
		}
		
		if (temporary) dicecol = Col.YELLOW;
		if (highlight > 0) dicecol = highlight;
		
		if (animation.length > 0){
			//Run the first animation
			for(i in 0 ... animation.length){
				if (!animation[i].active && !animation[i].finished){
					animation[i].start();
				}
				
				if (animation[i].active){
					animation[i].update();	
				}
			}
			
			if (animation[0].finished) animation.shift();
		}
	}
	
	public function drawoverlay(){
		if (showoverlayimage){
			if (overlayimage_animate > 0){
				graphic.overlayimage.x = x + shakex + overlayimage_xoff;
				graphic.overlayimage.y = y + shakey + overlayimage_yoff;
				graphic.overlayimage.frame = overlayimage_frame;
				graphic.overlayimage.draw();
				//FutureDraw.drawtile(x + shakex + overlayimage_xoff, y + shakey + overlayimage_yoff, overlayimage, overlayimage_frame, overlayimage_alpha);
			}else{
				//FutureDraw.drawimage(x + shakex + overlayimage_xoff, y + shakey + overlayimage_yoff, overlayimage, overlayimage_alpha);
			}
		}
	}
	
	public function draw(dicesize:Int = 242){
		if (!Screen.enabledisplay_dice) return;

		if (Combat.gamepadshowdicehighlight(this)) {
			Art.getdrawimage().show(x + shakex - 40, y + shakey - 40, "ui/gamepad/dice_highlight");
		}
		
		if (flash > 0){
			graphic.drawframe(this, 8);
		}else if (consumed || dicealpha != 1){
			//Gfx.scale(1 + (1 - dicealpha), 1 + (1 - dicealpha), Gfx.CENTER, Gfx.CENTER);
			//Game.drawdicealpha(x + shakex, y + shakey, value, dicecol, dicesize, dicealpha);
			//Gfx.scale(1, 1);
			graphic.alpha = dicealpha;
			graphic.draw(this);
		}else	if (locked){
			graphic.draw(this);
		}else if (blind){
			graphic.draw(this);
		}else {
			graphic.draw(this);
		}
		
		drawoverlay();
		
		if (burn){
			if (this == Combat.gamepad_hoverdice) {
				graphic.burntextbg.x = x + shakex - 60;
				graphic.burntextbg.y = y + shakey + 12*6;
				graphic.burntextbg.draw();
				graphic.burntext.drawtranslate(x + shakex + 120, y + shakey + 10.5 * 6, "Cost [heart]" + Rules.burningdicecost, Col.WHITE, 1.0, Locale.gamefontsmall, Text.CENTER);
			} else {
				graphic.burntext.drawtranslate(x + shakex + 120, y + shakey + 38 * 6, "Cost [heart]" + Rules.burningdicecost, Col.WHITE, 1.0, Locale.gamefontsmall, Text.CENTER);
			}
		}
		
		if (this.owner != null && this.owner.isplayer && Combat.gamepad_dicemode) {
			if (ControlMode.showgamepadui() && !Combat.selectspellslotmode && Combat.showgamepadcontrols()) {
				if (available() && !blind && Combat.gamepad_selectedequipment != null && !Combat.isdicevalidonequipment(this.basevalue, Combat.gamepad_selectedequipment)) {
					graphic.unacceptableimage.x = x + shakex - 40;
					graphic.unacceptableimage.y = y + shakey - 40;
					graphic.unacceptableimage.draw();
				}
			}
		}
	}
	
	public function consumenow(){
		if(!consumed){
			consumed = true;
			dicealpha = 0;
			priority = false;
			if(showoverlayimage) {
				burn = false;
				alternateburn = false;
				showoverlayimage = false;
				graphic.overlayimage.remove();
			}
		}
	}
	
	public function consumedice(){
		if(!consumed){
			consumed = true;
			priority = false;
			Actuate.tween(this, 0.25 / BuildConfig.speed, { dicealpha: 0 }).ease(Expo.easeIn);
			if(showoverlayimage) {
				burn = false;
				alternateburn = false;
				showoverlayimage = false;
				graphic.overlayimage.remove();
			}
		}
	}
	
	/* Specifically for dice disappearing when used on spellbooks */
	public function fastconsumedice(){
		if(!consumed){
			consumed = true;
			dicealpha = 0.8;
			priority = false;
			Actuate.tween(this, 0.125 / BuildConfig.speed, { dicealpha: 0 }).ease(Expo.easeIn);
			if(showoverlayimage) {
				burn = false;
				alternateburn = false;
				showoverlayimage = false;
				graphic.overlayimage.remove();
			}
		}
	}
	
	/* Specifically for dice disappearing when vanish is applied to them */
	public function veryfastconsumedice(vanishspeed:Float = 0.06125){
		if(!consumed){
			consumed = true;
			dicealpha = 0.8;
			priority = false;
			Actuate.tween(this, vanishspeed / BuildConfig.speed, { dicealpha: 0 }).ease(Expo.easeIn);
			if(showoverlayimage) {
				burn = false;
				alternateburn = false;
				showoverlayimage = false;
				graphic.overlayimage.remove();
			}
		}
	}
	
	public function animate(type:String, delay:Float = 0){
		var newanimation:Animation = new Animation();
		newanimation.applytodice(this);
		animation.push(newanimation);
		
		if (delay > 0){
			newanimation.adddelay(delay);
		}
		
		switch(type){
			case "burnfrozen":				
				newanimation.addcommand("soundevent", "_diceburn");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("textparticle", "Burn Freeze!", Col.WHITE);
				newanimation.addcommand("overlaytile", Status.FIRE, -(4 * 6) - 6, -(23 * 6) - 3, 0.02, 0.01);
				newanimation.addcommand("changetovalue", 1);
				newanimation.addcommand("reducestat", Status.FIRE);
				newanimation.addcommand("reducestat", Status.ICE);
				newanimation.addcommand("applyvariable", Status.FIRE);
				newanimation.addcommand("unlock");
			case Status.LOCK:
				newanimation.addcommand("soundevent", "_lock");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("textparticle", Locale.translate("Locked") + Locale.punctuationtranslate("!"), Col.WHITE);
				newanimation.addcommand("reducestat", Status.LOCK);
				newanimation.addcommand("applyvariable", Status.LOCK);
			case Status.ALTERNATE_LOCK:
				newanimation.addcommand("soundevent", "_lock");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("textparticle", Locale.translate("Locked") + Locale.punctuationtranslate("?!"), Col.WHITE);
				newanimation.addcommand("reducestat", Status.ALTERNATE_LOCK);
				newanimation.addcommand("applyvariable", Status.ALTERNATE_LOCK);
			/* Old split dice behaviour that kinda didn't work
			 * case Status.ALTERNATE_LOCK:
				newanimation.addcommand("soundevent", "_lock");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("textparticle", Locale.translate("Locked") + "?!", Col.WHITE);
				newanimation.addcommand("reducestat", Status.ALTERNATE_LOCK);
				newanimation.addcommand("splitdice");*/
			case Status.ALTERNATE_FIRE:
				newanimation.addcommand("soundevent", "_diceburn");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("textparticle", Locale.translate("Burn") + Locale.punctuationtranslate("?!"), 0xFF9999);
				newanimation.addcommand("overlaytile", Status.ALTERNATE_FIRE, -(4 * 6) - 6, -(23 * 6) - 3, 0.02, 0.01);
				newanimation.addcommand("reducestat", Status.ALTERNATE_FIRE);
				newanimation.addcommand("applyvariable", Status.ALTERNATE_FIRE);
			case Status.FIRE:
				newanimation.addcommand("soundevent", "_diceburn");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("textparticle", Locale.translate("Burn") + Locale.punctuationtranslate("!"), 0xFF9999);
				newanimation.addcommand("overlaytile", Status.FIRE, -(4 * 6) - 6, -(23 * 6) - 3, 0.02, 0.01);
				newanimation.addcommand("reducestat", Status.FIRE);
				newanimation.addcommand("applyvariable", Status.FIRE);
			case "disappear":
				newanimation.addcommand("shake", 0, -4);
				newanimation.addcommand("applyvariable", "destroy");
			case "snap", "flash":
				newanimation.addcommand("flash", 0.1);
			case "flashshake":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
			case "robotfrozen":
				newanimation.addcommand("soundevent", "_dicefreeze");
				newanimation.addcommand("overlaytileonce", Status.ICE, -(24 * 6) - 6, -(21 * 6), 0.01, 0.01);
			case "robotburn":
				newanimation.addcommand("soundevent", "_diceburn");
				newanimation.addcommand("overlaytile", Status.FIRE, -(4 * 6) - 6, -(23 * 6) - 3, 0.02, 0.01);
				newanimation.addcommand("applyvariable", Status.FIRE);
			case "robotalternateburn":
				newanimation.addcommand("soundevent", "_diceburn");
				newanimation.addcommand("overlaytile", Status.FIRE, -(4 * 6) - 6, -(23 * 6) - 3, 0.02, 0.01);
				newanimation.addcommand("applyvariable", Status.ALTERNATE_FIRE);
			case "robotalternateice":
				newanimation.addcommand("soundevent", "_dicefreeze");
				newanimation.addcommand("overlaytileonce", Status.ICE, -(24 * 6) - 6, -(21 * 6), 0.01, 0.01);
				newanimation.addcommand("shake", 0, -4);
				newanimation.adddelay(0.08);
				newanimation.addcommand("nudge");
				newanimation.addcommand("applyvariable", Status.ALTERNATE_ICE);
			case "robotalternatelock":
				newanimation.addcommand("soundevent", "_lock");
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0, -4);
				newanimation.adddelay(0.2);
				newanimation.addcommand("textparticle", Locale.translate("Locked") + Locale.punctuationtranslate("?!"), Col.WHITE);
				newanimation.addcommand("applyvariable", Status.ALTERNATE_LOCK);
			case Status.ICE:
				//newanimation.addcommand("shake", 0, -6);
				newanimation.addcommand("soundevent", "_dicefreeze");
				newanimation.addcommand("overlaytileonce", Status.ICE, -(24 * 6) - 6, -(21 * 6), 0.01, 0.01);
				//newanimation.addcommand("alphaimage", "frozendice", -4 * 6, -4 * 6, 0.25);
				newanimation.addcommand("textparticle", Locale.translate("Frozen") + Locale.punctuationtranslate("!"), Col.LIGHTBLUE);
				//newanimation.adddelay(0.3);
				newanimation.addcommand("shake", 0, -4);
				newanimation.adddelay(0.08);
				newanimation.addcommand("changetovalue", 1);
				newanimation.addcommand("reducestat", Status.ICE);
				newanimation.addcommand("unlock");
				/*
				if(basevalue >= 3){
					newanimation.adddelay(0.15);
					newanimation.addcommand("shake", 0, -4);
					newanimation.adddelay(0.08);
					newanimation.addcommand("nudge");
					newanimation.addcommand("nudge");
				}
				if(basevalue >= 4){
					newanimation.adddelay(0.15);
					newanimation.addcommand("shake", 0, -4);
					newanimation.adddelay(0.08);
					newanimation.addcommand("nudge");
				}*/
			case Status.ALTERNATE_ICE:
				//newanimation.addcommand("shake", 0, -6);
				newanimation.addcommand("overlaytileonce", Status.ICE, -(24 * 6) - 6, -(21 * 6), 0.01, 0.01);
				//newanimation.addcommand("alphaimage", "frozendice", -4 * 6, -4 * 6, 0.25);
				newanimation.addcommand("textparticle", Locale.translate("Frozen") + Locale.punctuationtranslate("!"), Col.LIGHTBLUE);
				//newanimation.adddelay(0.3);
				newanimation.addcommand("shake", 0, -4);
				newanimation.adddelay(0.08);
				newanimation.addcommand("nudge");
				newanimation.addcommand("reducestat", Status.ALTERNATE_ICE);
		}
	}
	
	/* Immediately have this dice be on fire, skipping animation step */
	public function burnnow(){
	  showoverlayimage = true;
		overlayimage = Status.FIRE;
		graphic.loadoverlay(Status.FIRE);
		overlayimage_xoff = -(4 * 6) - 6;
		overlayimage_yoff = -(23 * 6) - 3;
		overlayimage_alpha = 0.01;
		overlayimage_animate = 0.02;
		overlayimage_animatetime = 0.02;
		overlayimage_frame = 0;
		overlayimage_repeat = true;
		
		burn = true;
	}
	
	public function removeburneffect(){
		burn = false;
		alternateburn = false;
		overlayimage_alpha = 0;
		showoverlayimage = false;

		if (graphic != null) {
			if(graphic.overlayimage != null) graphic.overlayimage.remove();
			if(graphic.burntext != null) graphic.burntext.remove();
		}
	}
	
	public var animation:Array<Animation>;
	
	public var x:Float;
	public var y:Float;
	public var vx:Float;
	public var vy:Float;
	public var ax:Float;
	public var ay:Float;
	public var hasmotion:Bool;
	public var id:Int;
	public var assigned:Equipment;
	public var assignedposition:Int;

	public var startdraggingposition:Point;
	public var startdraggingposition_local:Point;
	public var dicesize:Int = 0;

	// this is the target position when rolling a new dice in combat
	public var targetx:Float;
	public var targety:Float;
	
	public var shakex:Float;
	public var shakey:Float;
	
	public var showoverlayimage(default, set):Bool;
	public var overlayimage:String;
	public var overlayimage_xoff:Float;
	public var overlayimage_yoff:Float;
	public var overlayimage_alpha:Float;
	public var overlayimage_animate:Float;
	public var overlayimage_animatetime:Float;
	public var overlayimage_frame:Int;
	public var overlayimage_repeat:Bool;
	
	public var temporary:Bool;
	public var altlock_lockedatstartturncheck:Bool;
	public var locked:Bool;
	public var priority:Bool;
	public var frozen:Bool;
	public var burn:Bool;
	public var alternateburn:Bool;
	public var highlight:Int = 0;
	public var consumed:Bool = false;
	public var dicealpha:Float = 1;
	public var inlerp:Bool = false;
	public var dicecol:Int;
	public var owner:Fighter;
	public var flash:Float;
	public var blind:Bool;
	public var ignitedthisturn:Bool;
	
	public var graphic:DiceGraphic;

	// if the dice can be moved by the player or not
	public var canbedragged:Bool = true;
	
	public var basevalue:Int;
	public var modifier:Int;
	public var value(get, never):Int;
	public function get_value(){
		return basevalue + modifier;
	}
	
	public function toString():String{
		var returnval:String;
		returnval = basevalue + "";
		if (assigned != null) returnval = "(" + returnval + ")";
		if (burn) returnval += "!";
		if (alternateburn) returnval += "alt!";
		if (priority) returnval += "PRIORITY";
		if (locked) returnval += "lock";
		return returnval;
	}

	function set_showoverlayimage(value:Bool) {
		showoverlayimage = value;
		if(!showoverlayimage) {
			burn = false;
			alternateburn = false;
			overlayimage_alpha = 0;
			if(graphic != null) {
				if(graphic.overlayimage != null) graphic.overlayimage.remove();
				if(graphic.burntext != null) graphic.burntext.remove();
			}
		}
		return showoverlayimage;
	}
	
	public var aiassigned:Equipment;
	public var justgrabbed:Bool;
	public var grabbed:Bool;
	public var released:Bool;
	public var touch:IndividualTouch;
}