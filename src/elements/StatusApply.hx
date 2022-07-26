package elements;

import displayobjects.TooltipManager;
import haxegon.*;

/* To do: maybe move status effect implementations into this one place, eventually? */ 
class StatusApply{
	//Apply all "start of turn" status scripts now
	public static function startturn(f:Fighter, isfleeing:Bool = false){
		if (f.hasstatus(Status.ALTERNATE + Status.SHIELD)){
			var alternateshield:StatusEffect = f.getstatus(Status.ALTERNATE + Status.SHIELD);
			Script.actionexecute(Script.load("attackself(-" + alternateshield.value + ");"), f, null, 0, [], null, null);
			AudioControl.play("_heal");
			f.removestatus(Status.ALTERNATE + Status.SHIELD);
		}
		
		if(!isfleeing) {
			applypoison(f);
		}
		
		
		//Finale Mode's "Against all Odds" will save you from poison, and then get removed
		if (f.hasstatus("againstallodds")){
			f.removestatus("againstallodds");
		}
		
		if (f.hasstatus(Status.ALTERNATE_SURVIVE)){
			var deathsentence:StatusEffect = f.getstatus(Status.ALTERNATE_SURVIVE);
			deathsentence.value--;
			deathsentence.displayvalue = deathsentence.value;
			if (deathsentence.value <= 0){
				f.removestatus(Status.ALTERNATE_SURVIVE);
				Script.actionexecute(Script.load("pierceattackself(" + f.hp + ", CURSE);"), f, null, 0, [], null, null);
				AudioControl.play("_curse");
			}
		}
		
		if (f.hasstatus("beartransform")){
			var beartransform:StatusEffect = f.getstatus("beartransform");
			beartransform.value--;
			beartransform.displayvalue = beartransform.value;
			if (beartransform.value <= 0){
				f.removestatus("beartransform");
				Game.actualbeartransform(f);
			}
		}
	}
	
	//Apply all "end of turn" status scripts now
	public static function endturn(f:Fighter){
		if (f.hasstatus(Status.ALTERNATE_BLIND)){
			var altblind:StatusEffect = f.getstatus(Status.ALTERNATE_BLIND);
			altblind.value--;
			if (altblind.value <= 0){
				f.removestatus(Status.ALTERNATE_BLIND);
			}else{
				altblind.displayvalue = altblind.value;
			}
		}
		
		if (f.hasstatus(Status.ALTERNATE + Status.POISON)){
			var altpoisondamage:Int = 0;
			for (e in f.equipment){
				if(e.shockedtype == "COUNTDOWN"){
					if (e.shockedsetting > 0){
						altpoisondamage = e.shocked_remainingcountdown;
					}
				}
			}
			
			if (altpoisondamage > 0){
				if (Innate.has(f, "absorbpoison")){
					Script.actionexecute(Script.load("attackself(-" + altpoisondamage + ");"), f, null, 0, [], null, null);
					f.symbolparticle(Status.POISON);
				}else if (Innate.has(f, "weakpoison")){
					Script.actionexecute(Script.load("pierceattackself(" + altpoisondamage + ", POISON);"), f, null, 0, [], null, null);
					AudioControl.play("take_damage_from_poison_status");
					f.symbolparticle(Status.POISON);
				}else if (Innate.has(f, "strongpoison")){
					Script.actionexecute(Script.load("pierceattackself(" + altpoisondamage + ", POISON);"), f, null, 0, [], null, null);
					AudioControl.play("take_damage_from_poison_status");
					f.symbolparticle(Status.POISON);
				}else if (Innate.has(f, "immunepoison")){
				}else{
					Script.actionexecute(Script.load("pierceattackself(" + altpoisondamage + ", POISON);"), f, null, 0, [], null, null);
					AudioControl.play("take_damage_from_poison_status");
					f.symbolparticle(Status.POISON);
				}
			}
			
			var altpoison:StatusEffect = f.getstatus(Status.ALTERNATE_POISON);
			altpoison.value--;
			if (altpoison.value <= 0){
				f.removestatus(Status.ALTERNATE_POISON);
			}else{
				altpoison.displayvalue = altpoison.value;
			}
		}
	}
	
	/* Apply status effects that require being checked on an update  */
	public static function update(f:Fighter, isplayer:Bool){			
		if (f.hasstatus(Status.VANISH)){
			if (f.hasstatus("fade")) f.removestatus("fade");
			var hasvalue:Array<Bool> = [false, false, false, false, false, false, false];
			var dicevanished:Bool = false;
			for (i in 0 ... f.dicepool.length){
				if (f.dicepool[i].available()){
					if (!f.dicepool[i].intween()){
						if (!hasvalue[f.dicepool[i].basevalue]){
							hasvalue[f.dicepool[i].basevalue] = true;
						}else{
							f.dicepool[i].animate("disappear");
							dicevanished = true;
						}
					}
				}
			}
			
			if (dicevanished){
				AudioControl.play("_diceburn");
			}
		}
		
		//Fade is a nicer version of Vanish that decrements with each dice used - from ncrmod.
		//ncrmod uses actuators to implement this, but it's easier for reunion if we just inline it
		if (f.hasstatus("fade")){
			var hasvalue:Array<Bool> = [false, false, false, false, false, false, false];
			var fadecount:Int = f.getstatus("fade").value;
			var dicevanished:Bool = false;
			for (i in 0 ... f.dicepool.length){
				if(fadecount > 0){
					if (f.dicepool[i].available()){
						if (!f.dicepool[i].intween()){
							if (!hasvalue[f.dicepool[i].basevalue]){
								hasvalue[f.dicepool[i].basevalue] = true;
							}else{
								f.dicepool[i].animate("disappear");
								dicevanished = true;
								fadecount--;
							}
						}
					}
				}
			}
			
			
			if (dicevanished){
				trace("new fadecount: " + fadecount);
				AudioControl.play("_diceburn");
				
				//Update fade value
				if (fadecount > 0){
					var overridedescription:String = f.getcoindescription("fade");
					var fadestatus:StatusEffect = f.getstatus("fade");
					fadestatus.value = fadecount;
					fadestatus._displayvalue = fadecount;
					fadestatus.updatedescription(overridedescription);
				}else{
					f.removestatus("fade");
				}
			}
		}
		
		//Hothead rule! Be on the lookout for unignited dice that match the ignition range
		if (Rules.ignitedice){
			for (d in f.dicepool){
				if(d.available() && d.ignitedthisturn == false){
					if (Rules.igniterange.indexOf(d.basevalue) > -1){
						if (Rules.hasalternate(Status.FIRE)){
							d.animate(Status.ALTERNATE_FIRE, 0.25 / BuildConfig.speed);
						}else{
							d.animate(Status.FIRE, 0.25 / BuildConfig.speed);
						}
						d.ignitedthisturn = true;
					}
				}
			}
		}
	}
	
	public static function applyonanyequipmentuse(f:Fighter, actualequipment:Equipment){
		if (f.hasstatus("cpuvirus")){
			Game.adjustrobotcounter(f, f.getstatus("cpuvirus").value);
		}
		
		if (f.hasstatus("haunted")){
			//Haunted is just the Sneezy rule
			var haunted:StatusEffect = f.getstatus("haunted");
			
			var availdice:Array<Dice> = [];
			for (mydice in f.dicepool){
				if (mydice.available() && !mydice.intween()){
					availdice.push(mydice); 
				} 
			} 
			
			if (availdice.length > 0) {
				availdice = Random.shuffle(availdice); 
				var newvalue:Int = Random.pick([1, 2, 3, 4, 5, 6]);
				if (Rules.reunioncoinmode){
					if (availdice[0].value >= 5){
						newvalue = Random.pick([5, 6]);
					}else{
						newvalue = Random.pick([1, 2]);
					}
				}
				availdice[0].animatereroll(newvalue, f.screenposition(), 0);  
				
				haunted.value--;
				haunted.displayvalue = haunted.value;
				if (haunted.value <= 0){
					f.removestatus("haunted");
				}
			}
		}
		
		//Custom status effect scripts
		for (i in 0 ... f.status.length){
			if(f.status[i] != null){
				if (f.status[i].value > 0) {
					if (f.status[i].scriptonanyequipmentuse != ""){
						f.status[i].runscript("onanyequipmentuse", 0, actualequipment);
					}
				}
			}
		}
	}
	
	public static function applyalternatelock(f:Fighter){
		//This is an update function, run over and over again to enforce the "alternate lock" rules
		//The *first* dice to have priority is unlocked. All others are locked.
		if (f.hadstatus(Status.ALTERNATE_LOCK)){
			//Unlock all dice
			var numpriority:Int = 0;
			var priority:Dice = null;
			for (d in f.dicepool){
				d.altlock_lockedatstartturncheck = d.locked;
				d.locked = false;
				if (d.priority){
					if (d.available()){						
						if(priority == null){
							priority = d;
						}
						numpriority++;
					}
				}
			}
			
			//Lock all dice *except* the priority
			if (priority != null){
				for (d in f.dicepool){
					if (d != priority){
						if (d.available()){	
							d.locked = true;
						}
					}
				}
			}
			
			//Do flash animations for dice that have changed state this frame
			for (d in f.dicepool){
				if (!d.locked && d.altlock_lockedatstartturncheck){
					//This dice was locked at the start of this process, and is now unlocked.
					//Do a flash animation!
					d.animate("flashshake");
				}else if (d.locked && !d.altlock_lockedatstartturncheck){
					//This dice was unlocked at the start of this process, and is now locked.
					//Do a flash animation!
					d.animate("flashshake");
				}
			}
			
			//Update the status display
			var altlock:StatusEffect = f.getstatus(Status.ALTERNATE_LOCK);
			if (altlock.value <= 0){
				if (numpriority <= 0){
					//If there are no priority dice, and there are no "alternate lock" status to implement, we can remove it.
					f.removestatus(Status.ALTERNATE_LOCK);
				}else{
					altlock.displayvalue = numpriority;
				}
			}
		}
	}
	
  public static function applypoison(f:Fighter){
		if (f.hasstatus(Status.POISON)){
			var poison:StatusEffect = f.getstatus(Status.POISON);
			if (Innate.has(f, "absorbpoison")){
				Script.actionexecute(Script.load("attackself(-" + poison.value + ");"), f, null, 0, [], null, null);
				f.symbolparticle(Status.POISON);
			}else if (Innate.has(f, "weakpoison")){
				Script.actionexecute(Script.load("pierceattackself(" + poison.value + ", POISON);"), f, null, 0, [], null, null);
				AudioControl.play("take_damage_from_poison_status");
				f.symbolparticle(Status.POISON);
			}else if (Innate.has(f, "strongpoison")){
				Script.actionexecute(Script.load("pierceattackself(" + poison.value + ", POISON);"), f, null, 0, [], null, null);
				AudioControl.play("take_damage_from_poison_status");
				f.symbolparticle(Status.POISON);
			}else if (Innate.has(f, "immunepoison")){
			}else{
				Script.actionexecute(Script.load("pierceattackself(" + poison.value + ", POISON);"), f, null, 0, [], null, null);
				AudioControl.play("take_damage_from_poison_status");
				f.symbolparticle(Status.POISON);
			}
			
			if(Game.player == f){
				poison.value += Rules.playerpoisondelta;
				poison.displayvalue = poison.value;
			}else{
				poison.value += Rules.enemypoisondelta;
				poison.displayvalue = poison.value;
			}
			if (poison.value <= 0){
				f.removestatus(Status.POISON);
			}
		}
	}
	
	public static function applyalternatereequipnext(f:Fighter, e:Equipment){
		if (f.hasstatus(Status.ALTERNATE + Status.REEQUIPNEXT)){
			var dexterity:StatusEffect = f.getstatus(Status.ALTERNATE + Status.REEQUIPNEXT);
			dexterity.value--;
			dexterity.displayvalue = dexterity.value;
			if (dexterity.value <= 0){
				f.removestatus(Status.ALTERNATE_REEQUIPNEXT);
			}
			
			for (i in 0 ... e.assigneddice.length){
				if(e.assigneddice[i] != null){
					var newdice:Dice = new Dice(e.assigneddice[i].x, e.assigneddice[i].y);
					newdice.owner = f;
					newdice.copyfrom(e.assigneddice[i]);
					e.assigneddice[i].temporary = true;
					f.dicepool.push(newdice);
				}
			}
		}
	}
}