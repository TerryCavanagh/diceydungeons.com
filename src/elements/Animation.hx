package elements;

import haxegon.*;
import motion.*;
import motion.easing.*;
import states.Combat;

class Animation{
  public function new(){
		dice = null;
		equipment = null;
		
		command = [];
		parameter = [];
		executed = [];
		timestamp = [];
		p1 = [];
		p2 = [];
		p3 = [];
		p4 = [];
		
		currenttime = 0;
		active = false;
		finished = false;
		
		type = "";
  }
	
	public function applytodice(d:Dice){
		dice = d;
		type = "dice";
	}
	
	public function applytoequipment(e:Equipment){
		equipment = e;
		type = "equipment";
	}
	
	public function addcommand(c:String, ?p:String="", ?v1:Float = 0, ?v2:Float = 0, ?v3:Float = 0, ?v4:Float = 0){
		command.push(c);
		parameter.push(p);
		p1.push(v1);
		p2.push(v2);
		p3.push(v3);
		p4.push(v4);
		executed.push(false);
		timestamp.push(currenttime);
	}
	
	public function adddelay(d:Float){
		currenttime += d / BuildConfig.speed;
	}
	
	public function start(){
		active = true;
		if (currenttime > timestamp[timestamp.length - 1]){
			addcommand("end");
		}
		currenttime = 0;
	}
	
	public function update(){
		if (!active) return;
		
		currenttime += Game.deltatime;
		
		var checkfinished:Bool = true;
		for (i in 0 ... command.length){
			if (!executed[i]){
				checkfinished = false;
				
				if (currenttime >= timestamp[i]){
					runcommand(command[i], parameter[i], p1[i], p2[i], p3[i], p4[i]);
					executed[i] = true;
				}
			}
		}
		
		if (checkfinished){
			finished = true;
			active = false;
		}
	}
	
	public function runcommand(c:String, para:String, v1:Float, v2:Float, v3:Float, v4:Float){
		switch(c){
			case "unlock":
				if (type == "dice"){
					dice.frozen = false;
				}
			case "soundevent":
				AudioControl.play(para);
		  case "waituntilready":
				if (type == "dice"){
					
				}else if (type == "equipment"){
					//if (Game.equipmentplaced < Game.equipmenttoplace){
					//	executed[i] = true;
					//}
				}
			case "applyvariable":
				if (type == "dice"){
					if (para == Status.FIRE){
						dice.burn = true;
					}
					if (para == Status.ALTERNATE_FIRE){
						dice.alternateburn = true;
					}
					if (para == Status.LOCK){
						dice.locked = true;
					}
					if (para == Status.ALTERNATE_LOCK){
						dice.priority = true;
					}
					if (para == "destroy"){
						AudioControl.play("vanish_applied_to_dice");
						Tutorial.showfastsmoke(dice.x + 250, dice.y + 300);
						dice.veryfastconsumedice();
						Combat.gamepad_pendingrearrange = true;
					}
				}else if (type == "equipment"){
					if (para == "unlock"){
						LockedRobotEquipment.changelockedslotstorealslots(equipment);
					}else if (para == Status.WEAKEN){
						equipment.downgrade();
					}else if (para == Status.SHOCK){
						if(equipment.equippedby == Game.player){
							if (Rules.shocktype == "EVEN"){
								equipment.shockedtype = DiceSlotType.EVEN;
							}else if (Rules.shocktype == "ODD"){
								equipment.shockedtype = DiceSlotType.ODD;
							}else if (Rules.shocktype == "RANDOM"){
								equipment.shockedtype = Random.pick([
									DiceSlotType.EVEN, DiceSlotType.ODD,
									DiceSlotType.REQUIRE1, DiceSlotType.REQUIRE2,
									DiceSlotType.REQUIRE3, DiceSlotType.REQUIRE4,
									DiceSlotType.REQUIRE5, DiceSlotType.REQUIRE6
								]);
							}else{
								equipment.shockedtype = DiceSlotType.NORMAL;
							}
						}else{
							equipment.shockedtype = DiceSlotType.NORMAL;
						}
						equipment.shockedsetting = 1;
						equipment.shockedtext = "Place a dice|to release shock";
						equipment.shockedcol = Pal.BLACK;
						equipment.shocked_showtitle = true;
						equipment.positionshockslots();
					}else if (para == Status.ALTERNATE_SHOCK){
						equipment.shockedtype = DiceSlotType.SKILL;
						equipment.shockedsetting = 1;
						equipment.shockedtext = "";
						equipment.shockedcol = Pal.BLACK;
						equipment.shocked_showtitle = true;
						equipment.positionshockslots();
					}else if (para == Status.ALTERNATE + Status.POISON){
						equipment.shockedtype = DiceSlotType.COUNTDOWN;
						equipment.shockedsetting = Std.int(v1);
						equipment.shockedtext = "Take [poison]<countdown> damage at the|end of this turn";
						equipment.shockedcol = Pal.PURPLE;
						equipment.shocked_showtitle = false;
						equipment.positionshockslots();
					}else if (para == Status.SILENCE){
						if (Game.player.hasstolencard){
							Game.player.stolencard.shockedtype = DiceSlotType.NORMAL;
							Game.player.stolencard.shockedsetting = 2;
							Game.player.stolencard.shockedtext = "Place two dice|to break silence";
							Game.player.stolencard.shockedcol = Pal.BLACK;
							Game.player.stolencard.shocked_showtitle = false;
							Game.player.stolencard.positionshockslots();
						}else{
							equipment.shockedtype = DiceSlotType.NORMAL;
							equipment.shockedsetting = 2;
							equipment.shockedtext = "Place two dice|to break silence";
							equipment.shockedcol = Pal.BLACK;
							equipment.shocked_showtitle = false;
							equipment.positionshockslots();
						}
					}
				}
			case "splitdice":
				if (type == "dice"){
					var basevalue:Int = dice.basevalue;
					Game.delaycall(function(){
					var dicevalue:Array<Int> = Game.split(basevalue, 2, true); 
						var newdice:Array<Dice>;
						var self:Fighter = Game.getactivefighter();
						if (self == Game.player){
							newdice = self.rolldice(2, Gfx.BOTTOM);
						}else{
							newdice = self.rolldice(2, Gfx.TOP);
						}
						newdice[0].basevalue = dicevalue[0];
						self.dicepool.push(newdice[0]);
						newdice[1].basevalue = dicevalue[1];
						self.dicepool.push(newdice[1]);
						
						if (self == Game.player) {
							if (!Combat.gamepad_dicemode) {
								Combat.gamepaddicetrail_prevdice = Combat.gamepad_selecteddice;
								Combat.gamepad_selecteddice = newdice[0];
							}
						}
					}, 0.5 / BuildConfig.speed);
					
					var olddicey:Float;
					if (Game.getactivefighter() == Game.player){
						olddicey = Screen.height + 100;
					}else{
						olddicey = -500;
					}
					
					//Destroy the initial dice
					Actuate.tween(dice, 0.3 / BuildConfig.speed, {
						x: dice.x, 
						y: olddicey})
						.ease(Back.easeIn)
						.onComplete(function(d:Dice){
							d.inlerp = false; 
							d.consumedice();
						}, [dice]);
				}
			case "flash":
				if (type == "dice"){
					dice.flash = v1;
				}else if (type == "equipment"){
					equipment.flashtime = v1;
				}
			case "shake":
				if (type == "dice"){
					if (v1 != 0){
						dice.shakex = v1;
						Actuate.tween(dice, 0.08 / BuildConfig.speed, { shakex: 0 });
					}
					if (v2 != 0){
						dice.shakey = v2;
						Actuate.tween(dice, 0.08 / BuildConfig.speed, { shakey: 0 });
					}
				}else if (type == "equipment"){
					if (v1 != 0){
						equipment.shakex = v1;
						Actuate.tween(equipment, 0.08 / BuildConfig.speed, { shakex: 0 });
					}
					if (v2 != 0){
						equipment.shakey = v2;
						Actuate.tween(equipment, 0.08 / BuildConfig.speed, { shakey: 0 });
					}
				}
			case "overlaytile":
				if (type == "dice"){
					dice.showoverlayimage = true;
					dice.overlayimage = para;
					dice.graphic.loadoverlay(para);
					dice.overlayimage_xoff = v1;
					dice.overlayimage_yoff = v2;
					dice.overlayimage_alpha = v4;
					dice.overlayimage_animate = v3;
					dice.overlayimage_animatetime = v3;
					dice.overlayimage_frame = 0;
					dice.overlayimage_repeat = true;
				}
			case "overlaytileonce":
				if (type == "dice"){
					dice.showoverlayimage = true;
					dice.overlayimage = para;
					dice.graphic.loadoverlay(para);
					dice.overlayimage_xoff = v1;
					dice.overlayimage_yoff = v2;
					dice.overlayimage_alpha = v4;
					dice.overlayimage_animate = v3;
					dice.overlayimage_animatetime = v3;
					dice.overlayimage_frame = 0;
					dice.overlayimage_repeat = false;
				}
			case "alphaimage":
				if (type == "dice"){
					dice.showoverlayimage = true;
					dice.overlayimage = para;
					dice.overlayimage_xoff = v1;
					dice.overlayimage_yoff = v2;
					dice.overlayimage_alpha = 0.7;
					dice.overlayimage_animate = 0;
					Actuate.tween(dice, v3 / BuildConfig.speed, { overlayimage_alpha: 0 })
					  .ease(Expo.easeIn)
						.onComplete(function(){
							dice.showoverlayimage = false;
						});
				}
			case "textparticle":
				if (type == "dice"){
					Particles.create(dice.x + 20 * 6, dice.y - 15 * 6, 1, "shorthoptext", para, Std.int(v1));
				}else if (type == "equipment"){
					Particles.create(equipment.x + Std.int(equipment.width / 2), equipment.y - 15 * 6, 1, "shorthoptext", para, Std.int(v1));
				}
			case "nudge":
				if (type == "dice"){
				  dice.basevalue = dice.basevalue - 1;
					if (dice.basevalue < 1){
						dice.basevalue = 1;
					}
				}
			case "changetovalue":
				if (type == "dice"){
				  dice.basevalue = Std.int(v1);
				}
			case "alphafadeout":
				if (type == "dice"){
					Actuate.tween(dice, 0.25 / BuildConfig.speed, { dicealpha: 0.0001 }).ease(Expo.easeIn);
				}else if (type == "equipment"){
					Actuate.tween(equipment, 0.25 / BuildConfig.speed, { equipalpha: 0.0001 }).ease(Expo.easeIn);
				}
			case "alphafadein":
				if (type == "dice"){
					Actuate.tween(dice, 0.25 / BuildConfig.speed, { dicealpha: 1 }).ease(Expo.easeIn);
				}
			case "removestatus":
				Game.player.removestatus(para);
			case "screenshake":
				Screen.shake();
			case "blackout":
				equipment.blackedout = true;
			case "cursedimage":
				if(para == "on"){
					equipment.cursedimage = 1;
				}else{
					//Actuate.tween(equipment, 0.5 / BuildConfig.speed, { cursedimage: 0 }).ease(Expo.easeOut);
				}
				if(v1 == 1) {
					equipment.useglitch = true;
				}
			case "reducestat":
				if (type == "dice"){
					if (para != Status.ICE){
						if (dice.owner.hasstatus(para)){
							var stat:StatusEffect = dice.owner.getstatus(para);
							stat.value--;
						}
					}
				}
			case "destroy":
				if (type == "dice"){
					Actuate.tween(dice, 0.3 / BuildConfig.speed, {
						x: dice.x, 
						y: Screen.height + 100})
						.ease(Back.easeIn)
						.onComplete(function(d:Dice){
							d.inlerp = false; 
							d.consumedice();
						}, [dice]);
				}
		}
	}
	
	public var type:String;
	public var dice:Dice;
	public var equipment:Equipment;
	public var command:Array<String>;
	public var parameter:Array<String>;
	public var p1:Array<Float>;
	public var p2:Array<Float>;
	public var p3:Array<Float>;
	public var p4:Array<Float>;
	public var timestamp:Array<Float>;
	public var executed:Array<Bool>;
	public var currenttime:Float;
	public var active:Bool;
	public var finished:Bool;
}