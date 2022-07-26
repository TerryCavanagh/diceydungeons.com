package elements;

import states.*;
import haxegon.*;
import displayobjects.*;
import elements.templates.*;
import haxe.Constraints.Function;
import motion.Actuate;
import motion.easing.*;
import openfl.Lib;
import openfl.geom.Point;
import elements.Dice;
import elements.Deck.DeckPublic;
import elements.Spellbook.SpellbookPublic;

class Equipment{
	public function new(_type:String, _upgraded:Bool = false, _weakened:Bool = false, _deckupgrade:Bool = false, ?pos:haxe.PosInfos){
		create(_type, _upgraded, _weakened, _deckupgrade, pos);
	}
	
	public function create(_type:String, _upgraded:Bool = false, _weakened:Bool = false, _deckupgrade:Bool = false, ?pos:haxe.PosInfos){
		if (S.isinstring(_type, "+")){
			_upgraded = true;
			name = S.trimspaces(S.getroot(_type, "+"));
		}else	if (S.isinstring(_type, "-")){
			_weakened = true;
			name = S.trimspaces(S.getroot(_type, "-"));
		}else{
			name = _type;
		}
		
		if (S.isinstring(name, "_")){
			if (S.isinstring(name, "_upgraded")){
				rawname = S.trimspaces(S.getroot(name, "_"));
				namemodifier = "+";
			}else if (S.isinstring(name, "_deckupgrade")){
				rawname = S.trimspaces(S.getroot(name, "_"));
				namemodifier = "+";
			}else {
				rawname = S.trimspaces(S.getroot(name, "_"));
				namemodifier = "-";
			}
		}else	if (S.isinstring(name, "+")){
			rawname = S.trimspaces(S.getroot(name, "+"));
			namemodifier = "+";
		}else if (S.isinstring(name, "-")){
			rawname = S.trimspaces(S.getroot(name, "-"));
			namemodifier = "-";
		}else{
			rawname = name;
			if (upgraded){
				namemodifier = "+";
			}else if (weakened){
				namemodifier = "-";
			}else{
				namemodifier = "";
			}
		}
		
		name_beforesubstitution = name;
		rawname_beforesubstitution = rawname;
		
		if(Rules.substitutions != null){
			if (Rules.substitutions.exists(rawname)){
				//trace("substituted " + rawname + " for " + Rules.substitutions.get(rawname) + " in " + pos.fileName + ":" + pos.className + "." + pos.methodName + ", line " + pos.lineNumber);
				rawname = Rules.substitutions.get(rawname);
				if (S.isinstring(name, "_")){
					name = rawname + "_" + S.getlastbranch(name, "_");
				}else	if (S.isinstring(name, "+")){
					name = rawname + "+";
				}else if (S.isinstring(name, "-")){
					name = rawname + "-";
				}else{
					name = rawname;
				}
				displayname = rawname;
			}
		}
		
		if (S.isinstring(rawname, "@")){
			displayname = S.getroot(rawname, "@");
		}else{
			displayname = rawname;
		}
		
		upgraded = _upgraded;
		weakened = _weakened;
		initvariables();
		resetvar();
		
		//Creating from template
		var template:EquipmentTemplate = Gamedata.getequipmenttemplate(name);
		
		if (Rules.monstermode){
			if (template == null){
			  template = Monstermode.createmonstercard(name);
			}
		}
		
		if (template != null){
			name = template.name;
			if (S.isinstring(template.name, "?")){
				if (!S.isinstring(displayname, "?")){
					displayname = name;
				}
			}
			size = template.size;
			if (Rules.bigequipmentmode) size = 2;
			fulldescription = template.fulldescription;
			overwritefinalline = "";
			for (i in 0 ... template.slots.length){
				addslots(template.slots[i]);
			}
			
			gadget = template.gadget;
			if (gadget == ""){
				gadget = "Broken Gadget";
			}
			
			needstotal = template.needstotal;
			if (slots.length > 0){
				if (slots[0] == DiceSlotType.COUNTDOWN){
					countdown = template.needstotal;
					maxcountdown = countdown;
					remainingcountdown = countdown;
					needstotal = 0;
				}
			}
			
			tags = [];
			for (i in 0 ... template.tags.length){
				tags.push(template.tags[i]);
			}
			
			allowupdatereuseabledescription = !hastag("hidereuseable");
			
			script = template.script;
			scriptbeforestartturn = template.scriptbeforestartturn;
			scriptbeforeexecute = template.scriptbeforeexecute;
			scriptonstartturn = template.scriptonstartturn;
			scriptendturn = template.scriptendturn;
			scriptbeforecombat = template.scriptbeforecombat;
			scriptaftercombat = template.scriptaftercombat;
			scriptonanyequipmentuse = template.scriptonanyequipmentuse;
			scriptonanycountdownreduce = template.scriptonanycountdownreduce;
			scriptiffury = template.scriptiffury;
			scriptonsnap = template.scriptonsnap;
			scriptondodge = template.scriptondodge;
			
			scriptrunner = null;
			castdirection = template.castdirection;
			upgradetype = template.upgradetype;
			weakentype = template.weakentype;
			equipmentcol = template.equipmentcol;
			reuseable = template.reuseable;
			usesleft = reuseable;
			updatereuseabledescription();
			tempreuseableequipment = [];
			reuseableanimation = 0;
			onceperbattle = template.onceperbattle;
			removefromthisbattle = false;
			
			sfxoverride = template.sfxoverride;
			playersound = template.playersound;
			enemysound = template.enemysound;
		}else{
			if (name == ""){
				//We can create no-named equipment and use them as a quick way to do certain animations
			}else{
				throw("Error: Trying to create equipment \"" + name + "\" (" + _type + ") from template, but cannot find a matching template in equipment.csv.");
			}
		}
		
		if (reuseable > 0){
			updatereuseabledescription();
		}
		
		if (upgradetype != ""){
			if (upgraded){
				namemodifier = "+";
				switch(upgradetype){
					case "reducesize":
						if (_deckupgrade){
							//instead of reducing the size, change to the alternate upgraded version
							//Make a placeholder panel to prevent it from getting overwriten with the unupgraded one
							equipmentpanel = new EquipmentPanel();
							create(rawname + "_deckupgrade", false);
							name = rawname;
							namemodifier = "+";
							upgradetype = "";
							upgraded = true;
							return;
						}else{
							size--;
							if (size < 0){
								throw("Cannot reduce size of " + name + " any further.");
							}
						}
					case "add1": addslots(DiceSlotType.FREE1);
					case "add2": addslots(DiceSlotType.FREE2);
					case "add3": addslots(DiceSlotType.FREE3);
					case "add4": addslots(DiceSlotType.FREE4);
					case "add5": addslots(DiceSlotType.FREE5);
					case "add6": addslots(DiceSlotType.FREE6);
					case "quartercountdown":
						countdown = Std.int(countdown / 4);
						remainingcountdown = countdown;
						maxcountdown = countdown;
				  case "thirdcountdown":
						countdown = Std.int(countdown / 3);
						remainingcountdown = countdown;
						maxcountdown = countdown;
					case "threequartercountdown":
						countdown = Std.int(countdown * 3 / 4);
						remainingcountdown = countdown;
						maxcountdown = countdown;
					case "twothirdcountdown":
						countdown = Std.int(countdown * 2 / 3);
						remainingcountdown = countdown;
						maxcountdown = countdown;
					case "halfcountdown":
						countdown = Std.int(countdown / 2);
						remainingcountdown = countdown;
						maxcountdown = countdown;
					case "everyturn":
						onceperbattle = false;
						overwritefinalline = "";
					case "reuseable":
						reuseable = -1;
						usesleft = -1;
						reuseableanimation = 0;
						tempreuseableequipment = [];
						updatereuseabledescription();
					case "increaserange":
						conditionalslots = false;
						for (i in 0 ... slots.length){
							if (slots[i] == DiceSlotType.MAX1 || slots[i] == DiceSlotType.REQUIRE1){
								slots[i] = DiceSlotType.MAX2;
							}else if (slots[i] == DiceSlotType.MAX2){
								slots[i] = DiceSlotType.MAX3;
							}else if (slots[i] == DiceSlotType.MAX3){
								slots[i] = DiceSlotType.MAX4;
							}else if (slots[i] == DiceSlotType.MAX4){
								slots[i] = DiceSlotType.MAX5;
							}else if (slots[i] == DiceSlotType.MAX5){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.REQUIRE6){
								slots[i] = DiceSlotType.MIN5;
							}else if (slots[i] == DiceSlotType.MIN5){
								slots[i] = DiceSlotType.MIN4;
							}else if (slots[i] == DiceSlotType.MIN4){
								slots[i] = DiceSlotType.MIN3;
							}else if (slots[i] == DiceSlotType.MIN3){
								slots[i] = DiceSlotType.MIN2;
							}else if (slots[i] == DiceSlotType.MIN2){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.RANGE23){
								slots[i] = DiceSlotType.MAX4;
							}else if (slots[i] == DiceSlotType.RANGE24){
								slots[i] = DiceSlotType.MAX5;
							}else if (slots[i] == DiceSlotType.RANGE25){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.RANGE34){
								slots[i] = DiceSlotType.RANGE25;
							}else if (slots[i] == DiceSlotType.RANGE35){
								slots[i] = DiceSlotType.MIN2;
							}else if (slots[i] == DiceSlotType.RANGE45){
								slots[i] = DiceSlotType.MIN3;
							}
							if (slots[i] == DiceSlotType.REQUIRE1 ||
								slots[i] == DiceSlotType.REQUIRE2 ||
								slots[i] == DiceSlotType.REQUIRE3 ||
								slots[i] == DiceSlotType.REQUIRE4 ||
								slots[i] == DiceSlotType.REQUIRE5 ||
								slots[i] == DiceSlotType.REQUIRE6){
								conditionalslots = true;
							}
						}
						
					case "simplify":
						conditionalslots = false;
						for (i in 0 ... slots.length){
							if (slots[i] == DiceSlotType.EVEN){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.ODD){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.MAX1){
								slots[i] = DiceSlotType.MAX2;
							}else if (slots[i] == DiceSlotType.REQUIRE1){
								slots[i] = DiceSlotType.ODD;
							}else if (slots[i] == DiceSlotType.REQUIRE2){
								slots[i] = DiceSlotType.EVEN;
							}else if (slots[i] == DiceSlotType.REQUIRE3){
								slots[i] = DiceSlotType.ODD;
							}else if (slots[i] == DiceSlotType.REQUIRE4){
								slots[i] = DiceSlotType.EVEN;
							}else if (slots[i] == DiceSlotType.REQUIRE5){
								slots[i] = DiceSlotType.ODD;
							}else if (slots[i] == DiceSlotType.REQUIRE6){
								slots[i] = DiceSlotType.EVEN;
							}else if (slots[i] == DiceSlotType.MIN2){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.MIN4){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.MAX3){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.MAX4){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.MAX5){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.RANGE23){
								slots[i] = DiceSlotType.MAX4;
								conditionalslots = true;
							}else if (slots[i] == DiceSlotType.RANGE24){
								slots[i] = DiceSlotType.MAX5;
								conditionalslots = true;
							}else if (slots[i] == DiceSlotType.RANGE25){
								slots[i] = DiceSlotType.NORMAL;
							}else if (slots[i] == DiceSlotType.RANGE34){
								slots[i] = DiceSlotType.RANGE25;
								conditionalslots = true;
							}else if (slots[i] == DiceSlotType.RANGE35){
								slots[i] = DiceSlotType.MIN2;
								conditionalslots = true;
							}else if (slots[i] == DiceSlotType.RANGE45){
								slots[i] = DiceSlotType.MIN3;
								conditionalslots = true;
							}
							if (slots[i] == DiceSlotType.REQUIRE1 ||
								slots[i] == DiceSlotType.REQUIRE2 ||
								slots[i] == DiceSlotType.REQUIRE3 ||
								slots[i] == DiceSlotType.REQUIRE4 ||
								slots[i] == DiceSlotType.REQUIRE5 ||
								slots[i] == DiceSlotType.REQUIRE6){
								conditionalslots = true;
							}
						}
					case "change_power", "change_poison", "change_requirements", 
					     "change_description", "change_boomerang", "change_countdown",
							 "change_backfire", "change_towershield":
						//Make a placeholder panel to prevent it from getting overwriten with the unupgraded one
						equipmentpanel = new EquipmentPanel();
						if (name_beforesubstitution != name){
							create(rawname_beforesubstitution + "_upgraded", false);
						}else{
							create(rawname + "_upgraded", false);
						}
						name = rawname;
						namemodifier = "+";
						upgradetype = "";
						upgraded = true;
						return;
				}
				upgradetype = "";
			}
		}
		
		if (weakened){
			if(downgrade()) return;
		}
		
		assigneddice = [];
		for (i in 0 ... slots.length){
			assigneddice.push(null);
		}
		
		if (slots.length > 0){
			if (slots[0] == DiceSlotType.DOUBLES){
				//SPECIAL CASE WOO
				needsdoubles = true;
			}else if (slots[0] == DiceSlotType.LOCKED2){
				locked = 2;
			}else if (slots[0] == DiceSlotType.LOCKED3){
				locked = 3;
			}else if (slots[0] == DiceSlotType.LOCKED4){
				locked = 4;
			}else if (slots[0] == DiceSlotType.LOCKED5){
				locked = 5;
			}else if (slots[0] == DiceSlotType.LOCKED6){
				locked = 6;
			}else if (slots[0] == DiceSlotType.LOCKED7){
				locked = 7;
			}else if (slots[0] == DiceSlotType.COMBINATION){
				combination = true;
			}
			unlocked = 0;
			unlockedthisturn = false;
			unlockflash = 0;
			combinationflash = 0;
		}
		
		if (size == 1){
			width = 132 * 6;
			height = 102 * 6;
		}else if (size == 2){
			width = 132 * 6;
			height = 150 * 6;
		}else if (size == 3){
			width = 264 * 6;
			height = 102 * 6;
		}else if (size == 4){
			width = 264 * 6;
			height = 150 * 6;
		}
		
		arrangeslots();
		
		if (name == "Warrior Skillcard"){
			//for (i in 0 ... slotpositions.length){
			//	slotpositions[i].y += 45;
			//}
		}
		
		if (name == "Witch Skillcard"){
			slotpositions[0].x = width - 65 * 6;
			slotpositions[0].y = 40 * 6;
			/*
			slotpositions[1].x = slotpositions[0].x;
			slotpositions[1].y = slotpositions[0].y + 62 * 6;*/
		}
		
		ispowercard = false;
		if (hastag("powercard")){
			equipmentpanel = new BackupCard();
			cast(equipmentpanel, BackupCard).setupbackup(this, false);
			ispowercard = true;
		}else if (hastag("monstercard")){
			equipmentpanel = new BackupCard();
			cast(equipmentpanel, BackupCard).setupbackup(this, true);
		}else{
			if(equipmentpanel == null){
				equipmentpanel = new EquipmentPanel();
			}
		}
	}
	
	public function makeskillcard(){
		skillcard = "normal";
		skillcard_special = false;
	}
	
	public function resize(newsize:Int){
		if (size == newsize) return;
		
		size = newsize;
		
		//This is only ever 2, right? Let's hardcode it for now
		if (size != 2){
			trace("Warning: Cannot resize to sizes other than 2 right now.");
			return;
		}
		
		if(size == 2){
			width = 132 * 6;
			height = 150 * 6;
		}
		
		arrangeslots();
	}
	
	public function initvariables(){
		if (Rules.bigequipmentmode){
			size = 2;
		}else{
			size = 1;
		}
		ready = true;
		active = true;
		
		x = 0;
		y = 0;
		shakex = 0;
		shakey = 0;
		
		onetimecheck = false;
		
		show = true;
		
		availablethisturn = true;
		availablenextturn = true;
		unavailabletext = "Unavailable";
		unavailablemodifier = "";
		unavailabledetails = [];
		castdirection = 1;
		skillcard = "";
		skillcard_special = false;
		needstotal = 0;
		conditionalslots = false;
		script = "";
		scriptrunner = null;
		slots = [];
		if (skills != null){
			if (skills.length > 0){
			  for (i in 0 ... skills.length) skills[i].dispose();
			}
		}
		skills = [];
		slotshake = [];
		skillsavailable = [];
		skills_temporarythisfight = [];
		upgradetype = "";
		ignoredicevalue = false;
		equipmentcol = -1;
		shockedtype = "NORMAL";
		shockedsetting = 0;
		shockedtext = "";
		shocked_textoffset = 0;
		shockedcol = Pal.BLACK;
		shocked_showtitle = true;
		shocked_returndice = false;
		shocked_needstotal = 0;
		unshockingtimer = 0;
		needsdoubles = false;
		combination = false;
		locked = 0;
		unlocked = 0;
		unlockedthisturn = false;
		unlockflash = 0;
		combinationflash = 0;
		priority = 2;
		aihints = "";
		timesused = 0;
		totalusesremaining = Rules.inventor_equipmentrust;
		charge = 0;
		equipalpha = 1.0;
		gamepadalpha = 1.0;
		cursedimage = 0;
		useglitch = false;
		blackedout = false;
		preventdefault = false;
		maintainfury = false;
		alreadyfuryed = false;
		descriptiontextoffset = 0;
		ispowercard = false;
		
		reuseable = 0;
		reuseableanimation = 0;
		reuseableoriginalx = 0;
		reuseableoriginaly = 0;
		tempreuseableequipment = [];
		
		weakened = false;
		originallyupgraded = false;
		
		animation = [];
		onanimatecomplete = null;
		onanimatecomplete_selectedslot = 0;
		onanimatecomplete_actor = null;
		onanimatecomplete_equipment = null;
		
		countdown = 0;
		reducecountdownby = 0;
		reducecountdowndelay = 0;
		remainingcountdown = 0;
		maxcountdown = 0;
		
		onceperbattle = false;
		usedthisbattle = false;
		removefromthisbattle = false;
		
	  temporary_thisturnonly = false;
		overwritefinalline = "";
		
		showhealthbar = false;
		monstercard = null;
		
		allowupdatereuseabledescription = true;
		
		tags = [];
		
		rustcounter = [];
		cleardicehistory();
	}
	
	public function positionshockslots(resetassignments:Bool = true){
		if(resetassignments) shocked_assigneddice = [];
		shocked_slots = [];
		shocked_slotpositions = [];
		
		if (shockedsetting > 0){
			if (shockedtype == "SKILL"){
				if (resetassignments) shocked_assigneddice = [null];
				shocked_slots = [DiceSlotType.SKILL];
				if (size == 2){
					shocked_slotpositions = [new Point(Std.int((width / 2) - 20 * 6), Std.int(((height - 40 * 6) / 2) - 6 * 6))];
					shocked_textoffset = 0;
				}else{
					shocked_slotpositions = [new Point(Std.int((width / 2) - 20 * 6), Std.int((height / 2) - 40 * 6))];
					shocked_textoffset = 10 * 6;
				}
			}else	if (shockedtype == "COUNTDOWN"){
				if (resetassignments) shocked_assigneddice = [null];
				shocked_slots = [DiceSlotType.COUNTDOWN];
				if (size == 2){
					shocked_slotpositions = [new Point(Std.int((width / 2) - 20 * 6), Std.int(((height - 40 * 6) / 2) - 6 * 6))];
					shocked_textoffset = 0;
				}else{
					shocked_slotpositions = [new Point(Std.int((width / 2) - 20 * 6), Std.int((height / 2) - 40 * 6))];
					shocked_textoffset = 10 * 6;
				}
				shocked_needstotal = 0;
				shocked_countdown = shockedsetting;
				shocked_remainingcountdown = shocked_countdown;
			}else	if (shockedtype == "MUSTEQUAL"){
				shocked_needstotal = shockedsetting;
				shocked_slots = [DiceSlotType.NORMAL, DiceSlotType.NORMAL];
				shocked_slotpositions = [new Point(Std.int((width / 2) - 20 * 6), Std.int(((height - 40 * 6) / 2) - 6 * 6))];
				shocked_textoffset = 0;
			}else{
				if(shockedsetting == 1){
					if (resetassignments) shocked_assigneddice = [null];
					shocked_slots = [Game.convert_string_to_diceslottype(shockedtype)];
					shocked_slotpositions = [new Point(Std.int((width / 2) - 20 * 6), Std.int(((height - 40 * 6) / 2) - 6 * 6))];
					shocked_textoffset = 0;
				}else if (shockedsetting == 2){
					if(resetassignments) shocked_assigneddice = [null, null];
					shocked_slots = [Game.convert_string_to_diceslottype(shockedtype), Game.convert_string_to_diceslottype(shockedtype)];
					shocked_slotpositions = [
						new Point(Std.int((width / 2) - 290), Std.int((((height - 40 * 6) / 2) - 6 * 6))),
						new Point(Std.int((width / 2) + 270 - 40 * 6), Std.int((((height - 40 * 6) / 2) - 6 * 6))),
					];
					shocked_textoffset = 0;
					
					if (skillcard == "inventor" || skillcard == "skillskillcard"){
						if(skills != null){
							if (skills.length == 1){
								shocked_slotpositions[0].y -= 12 * 6;
								shocked_slotpositions[1].y -= 12 * 6;
							}
						}
					} else if (skillcard == "witch"){
						shocked_slotpositions[0].y -= 25 * 6;
						shocked_slotpositions[1].y -= 25 * 6;
					}
				}
			}
		}
	}
	
	public function arrangeslots(){
		//Auto arrange slots on the equipment card.
		slotpositions = [];
		descriptiontextoffset = 0;
		
		var twidth:Int = Std.int(width - 24);
		var theight:Int = Std.int(height);
		var tspacing:Int = 280;
		
		positionshockslots();
		
		if (slots.length == 0) return;
		
		if (size == 1){
			//Max 2 slots
			if (slots.length == 1){
				slotpositions.push(new Point((twidth / 2) - 20 * 6, 27 * 6));
			}else if (slots.length == 2){
				if (needsdoubles){
					slotpositions.push(new Point((twidth / 2) - 40 * 6 - 2 * 6, 27 * 6));
					slotpositions.push(new Point((twidth / 2) + 2 * 6, 27 * 6));
				}else{
					slotpositions.push(new Point((twidth / 2) - tspacing, 27 * 6));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, 27 * 6));
				}
			}else if (slots.length == 3){
				slotpositions.push(new Point((twidth / 2) - 62 * 6 + 1 * 6, 27 * 6));
				slotpositions.push(new Point((twidth / 2) - 20 * 6 + 1 * 6, 27 * 6));
				slotpositions.push(new Point((twidth / 2) + 22 * 6 + 1 * 6, 27 * 6));
			}else{
				throw("Error: A size 1 equipment card cannot have more than 3 slots. (\"" + name + "\" has " + slots.length + ".)");
			}
			
			var tempdescription = Locale.translatearray(fulldescription);
			if (tempdescription.length == 3){
				for (i in 0 ... slotpositions.length){
					slotpositions[i].y -= 4 * 6;
				}
				
				if (needstotal > 0 || needsdoubles || conditionalslots){
					for (i in 0 ... slotpositions.length){
						slotpositions[i].y -= 8 * 6;
					}
				}
			}else	if (tempdescription.length == 2){
				for (i in 0 ... slotpositions.length){
					slotpositions[i].y -= 2 * 6;
				}
				
				if (needstotal > 0 || needsdoubles || conditionalslots){
					for (i in 0 ... slotpositions.length){
						slotpositions[i].y -= 4 * 6;
					}
				}
			}else{
				if (needstotal > 0 || needsdoubles || conditionalslots){
					for (i in 0 ... slotpositions.length){
						slotpositions[i].y -= 5 * 6;
					}
				}
			}
		}else if (size == 2){
			//Max 4 slots.
			if (slots.length == 1){
				if (needstotal > 0 || conditionalslots){
					slotpositions.push(new Point((twidth / 2) - 20 * 6, ((theight - 40 * 6) / 2) - 5));
				}else{
					slotpositions.push(new Point((twidth / 2) - 20 * 6, ((theight - 40 * 6) / 2)));
				}
			}else if (slots.length == 2){
				if (needsdoubles){
					slotpositions.push(new Point((twidth / 2) - 40 * 6 - 2 * 6, ((theight - 40 * 6) / 2) - 5));
					slotpositions.push(new Point((twidth / 2) + 2 * 6, ((theight - 40 * 6) / 2) - 5));
				}else	if (needstotal > 0 || conditionalslots){
					slotpositions.push(new Point((twidth / 2) - tspacing, ((theight - 40 * 6) / 2) - 5));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, ((theight - 40 * 6) / 2) - 5));
				}else{
					slotpositions.push(new Point((twidth / 2) - tspacing, ((theight - 40 * 6) / 2)));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, ((theight - 40 * 6) / 2)));
				}
			}else if (slots.length == 3){
				if (needstotal > 0 || needsdoubles || conditionalslots){
					slotpositions.push(new Point((twidth / 2) - tspacing, ((theight - 40 * 6) / 4) - 40));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, ((theight - 40 * 6) / 4) - 40));
					slotpositions.push(new Point((twidth / 2) - 20 * 6, slotpositions[0].y + 240 + 80));
					
					descriptiontextoffset = 30;
				}else{
					slotpositions.push(new Point((twidth / 2) - tspacing, ((theight - 40 * 6) / 4)));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, ((theight - 40 * 6) / 4)));
					slotpositions.push(new Point((twidth / 2) - 20 * 6, slotpositions[0].y + 280));
				}
			}else if (slots.length == 4){
				if (needstotal > 0 || needsdoubles || conditionalslots){
					slotpositions.push(new Point((twidth / 2) - tspacing, ((theight - 40 * 6) / 4) - 40));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, ((theight - 40 * 6) / 4) - 40));
					
					slotpositions.push(new Point((twidth / 2) - tspacing, slotpositions[0].y + 240 + 80));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, slotpositions[0].y + 240 + 80));
					
					descriptiontextoffset = 30;
				}else{
					slotpositions.push(new Point((twidth / 2) - tspacing, ((theight - 40 * 6) / 4)));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, ((theight - 40 * 6) / 4)));
					
					slotpositions.push(new Point((twidth / 2) - tspacing, slotpositions[0].y + 280));
					slotpositions.push(new Point((twidth / 2) + tspacing - 40 * 6, slotpositions[0].y + 280));
				}
			}else{
				throw("Error: A size 2 equipment card cannot have more than 4 slots. (\"" + name + "\" has " + slots.length + ".)");
			}
			
			var tempdescription = Locale.translatearray(fulldescription);
			if (tempdescription.length == 4){
				for (i in 0 ... slotpositions.length){
					slotpositions[i].y -= 90;
				}
			}
		}
		
		for (i in 0 ... slotpositions.length){
			slotpositions[i].y -= 27;
		}
	}
	
	public function changecolour(newcolour:String){
		newcolour = newcolour.toUpperCase();
		switch(newcolour){
			case "GRAY": equipmentcol = Pal.GRAY;
			case "BLUE": equipmentcol = Pal.BLUE;
			case "RED": equipmentcol = Pal.RED;
			case "GREEN": equipmentcol = Pal.GREEN;
			case "YELLOW": equipmentcol = Pal.YELLOW;
			case "PURPLE": equipmentcol = Pal.PURPLE;
			case "CYAN": equipmentcol = Pal.CYAN;
			case "WHITE": equipmentcol = Pal.WHITE;
			case "BRIGHTCYAN": equipmentcol = Pal.BRIGHTCYAN;
			case "ORANGE": equipmentcol = Pal.ORANGE;
			case "BLACK": equipmentcol = Pal.BLACK;
			case "PINK": equipmentcol = Pal.PINK;
		}
		
		//Force a redraw
		equipmentpanel.dispose();
	}
	
	/* Restore the original slots from the template */
	public function resetslots(){
		//We remove the existing slots:
		slots = [];
		slotshake = [];
		conditionalslots = false;
		
		var template:EquipmentTemplate = Gamedata.getequipmenttemplate(name);
		if (template != null){
			for (i in 0 ... template.slots.length){
				addslots(template.slots[i]);
			}
		}
		
		arrangeslots();
		//Force a redraw of the slots
		equipmentpanel.dispose();
	}
	
	/* Change the current slots in string format (for scripting) */
	public function changeslots(newslots:Array<String>){
		var setcombination:Bool = false;
		if (newslots.length > 0){
			if (newslots[0] == "COMBINATION"){
				setcombination = true;
			}
		}
		
		//We remove the existing slots:
		slots = [];
		slotshake = [];
		conditionalslots = false;
		countdown = 0;
		reducecountdownby = 0;
		reducecountdowndelay = 0;
		remainingcountdown = 0;
		maxcountdown = 0;
		needstotal = 0;
		needsdoubles = false;
		if(!setcombination){
			if (combination = true) Combination.dispose(this);
			combination = false;
		}else{
			combination = true;
			addslots(DiceSlotType.COMBINATION);
			
			//Force a redraw of the slots
			equipmentpanel.dispose();
			equipmentpanel = null;
			equipmentpanel = new EquipmentPanel();
			return;
		}
		
		for (i in 0 ... newslots.length){
			switch(newslots[i]){
				case "NORMAL": addslots(DiceSlotType.NORMAL);
				case "REQUIRE1": addslots(DiceSlotType.REQUIRE1);
				case "REQUIRE2": addslots(DiceSlotType.REQUIRE2);
				case "REQUIRE3": addslots(DiceSlotType.REQUIRE3);
				case "REQUIRE4": addslots(DiceSlotType.REQUIRE4);
				case "REQUIRE5": addslots(DiceSlotType.REQUIRE5);
				case "REQUIRE6": addslots(DiceSlotType.REQUIRE6);
				case "FREE1": addslots(DiceSlotType.FREE1);
				case "FREE2": addslots(DiceSlotType.FREE2);
				case "FREE3": addslots(DiceSlotType.FREE3);
				case "FREE4": addslots(DiceSlotType.FREE4);
				case "FREE5": addslots(DiceSlotType.FREE5);
				case "FREE6": addslots(DiceSlotType.FREE6);
				case "EVEN": addslots(DiceSlotType.EVEN);
				case "ODD": addslots(DiceSlotType.ODD);
				case "MAX1": addslots(DiceSlotType.MAX1);
				case "MAX2": addslots(DiceSlotType.MAX2);
				case "MAX3": addslots(DiceSlotType.MAX3);
				case "MAX4": addslots(DiceSlotType.MAX4);
				case "MAX5": addslots(DiceSlotType.MAX5);
				case "MIN2": addslots(DiceSlotType.MIN2);
				case "MIN3": addslots(DiceSlotType.MIN3);
				case "MIN4": addslots(DiceSlotType.MIN4);
				case "MIN5": addslots(DiceSlotType.MIN5);
				case "RANGE23": addslots(DiceSlotType.RANGE23);
				case "RANGE24": addslots(DiceSlotType.RANGE24);
				case "RANGE25": addslots(DiceSlotType.RANGE25);
				case "RANGE34": addslots(DiceSlotType.RANGE34);
				case "RANGE35": addslots(DiceSlotType.RANGE35);
				case "RANGE45": addslots(DiceSlotType.RANGE45);
				case "SPARE1": 
				  addslots(DiceSlotType.SPARE1);
					if (assigneddice != null){
						if (assigneddice.length >= i){
							if (assigneddice[i] != null){
								assigneddice[i].basevalue = 1;
							}
						}
					}
				case "SPARE2": 
				  addslots(DiceSlotType.SPARE2);
					if (assigneddice != null){
						if (assigneddice.length >= i){
							if (assigneddice[i] != null){
								assigneddice[i].basevalue = 2;
							}
						}
					}
				case "SPARE3": 
				  addslots(DiceSlotType.SPARE3);
					if (assigneddice != null){
						if (assigneddice.length >= i){
							if (assigneddice[i] != null){
								assigneddice[i].basevalue = 3;
							}
						}
					}
				case "SPARE4": 
				  addslots(DiceSlotType.SPARE4);
					if (assigneddice != null){
						if (assigneddice.length >= i){
							if (assigneddice[i] != null){
								assigneddice[i].basevalue = 4;
							}
						}
					}
				case "SPARE5": 
				  addslots(DiceSlotType.SPARE5);
					if (assigneddice != null){
						if (assigneddice.length >= i){
							if (assigneddice[i] != null){
								assigneddice[i].basevalue = 5;
							}
						}
					}
				case "SPARE6": 
				  addslots(DiceSlotType.SPARE6);
					if (assigneddice != null){
						if (assigneddice.length >= i){
							if (assigneddice[i] != null){
								assigneddice[i].basevalue = 6;
							}
						}
					}
				case "DOUBLES": 
				  addslots(DiceSlotType.DOUBLES, 2);
					needsdoubles = true;
				default:
				  //Countdowns
					if (S.isinstring(newslots[i], "COUNTDOWN_")){
						var countdownval:Int = Std.parseInt(S.getbranch(newslots[i], "_"));
						addslots(DiceSlotType.COUNTDOWN);
						countdown = countdownval;
						maxcountdown = countdown;
						remainingcountdown = countdown;
						needstotal = 0;
					}else if (S.isinstring(newslots[i], "MUSTEQUAL")){
						needstotal = Std.parseInt(S.removefromleft(newslots[i], "MUSTEQUAL".length));
						if (needstotal <= 12){
							addslots(DiceSlotType.NORMAL, 2);
						}else{
							addslots(DiceSlotType.NORMAL, Std.int(((needstotal - (needstotal % 6)) / 6) + 1));
						}
					}else{
						trace("Error: Cannot change slots on " + displayname + namemodifier + " to " + newslots[i] + ", not supported yet.");
					}
			}
		}
		
		arrangeslots();
		if(assigneddice.length != slots.length){
			assigneddice = [];
			for (i in 0 ... slots.length){
				assigneddice.push(null);
			}
		}
		//Force a redraw of the slots
		equipmentpanel.dispose();
	}
	
	/* Get a list of current slots in a string format (for scripting) */
	public function getslots():Array<String>{
		var returnlist:Array<String> = [];
		
		for (i in 0 ... slots.length){
			switch(slots[i]){
				case DiceSlotType.NORMAL: returnlist.push("NORMAL");
				case DiceSlotType.REQUIRE1: returnlist.push("REQUIRE1");
				case DiceSlotType.REQUIRE2: returnlist.push("REQUIRE2");
				case DiceSlotType.REQUIRE3: returnlist.push("REQUIRE3");
				case DiceSlotType.REQUIRE4: returnlist.push("REQUIRE4");
				case DiceSlotType.REQUIRE5: returnlist.push("REQUIRE5");
				case DiceSlotType.REQUIRE6: returnlist.push("REQUIRE6");
				case DiceSlotType.FREE1: returnlist.push("FREE1");
				case DiceSlotType.FREE2: returnlist.push("FREE2");
				case DiceSlotType.FREE3: returnlist.push("FREE3");
				case DiceSlotType.FREE4: returnlist.push("FREE4");
				case DiceSlotType.FREE5: returnlist.push("FREE5");
				case DiceSlotType.FREE6: returnlist.push("FREE6");
				case DiceSlotType.EVEN: returnlist.push("EVEN");
				case DiceSlotType.ODD: returnlist.push("ODD");
				case DiceSlotType.MAX1: returnlist.push("MAX1");
				case DiceSlotType.MAX2: returnlist.push("MAX2");
				case DiceSlotType.MAX3: returnlist.push("MAX3");
				case DiceSlotType.MAX4: returnlist.push("MAX4");
				case DiceSlotType.MAX5: returnlist.push("MAX5");
				case DiceSlotType.MIN2: returnlist.push("MIN2");
				case DiceSlotType.MIN3: returnlist.push("MIN3");
				case DiceSlotType.MIN4: returnlist.push("MIN4");
				case DiceSlotType.MIN5: returnlist.push("MIN5");
				case DiceSlotType.SPARE1: returnlist.push("SPARE1");
				case DiceSlotType.SPARE2: returnlist.push("SPARE2");
				case DiceSlotType.SPARE3: returnlist.push("SPARE3");
				case DiceSlotType.SPARE4: returnlist.push("SPARE4");
				case DiceSlotType.SPARE5: returnlist.push("SPARE5");
				case DiceSlotType.SPARE6: returnlist.push("SPARE6");
				case DiceSlotType.RANGE23: returnlist.push("RANGE23");
				case DiceSlotType.RANGE24: returnlist.push("RANGE24");
				case DiceSlotType.RANGE25: returnlist.push("RANGE25");
				case DiceSlotType.RANGE34: returnlist.push("RANGE34");
				case DiceSlotType.RANGE35: returnlist.push("RANGE35");
				case DiceSlotType.RANGE45: returnlist.push("RANGE45");
			  case DiceSlotType.DOUBLES: 
				  return ["DOUBLES"];
			  case DiceSlotType.COUNTDOWN: 
				  returnlist.push("COUNTDOWN_" + maxcountdown);
				default:
					returnlist.push("NORMAL");
			}
		}
		
		return returnlist;
	}
	
	public function addslots(_type:DiceSlotType, num:Int = 1){
		for(i in 0 ... num){
			slots.push(_type);
			slotshake.push(new Point(0, 0));
		}
		
		if (_type == DiceSlotType.REQUIRE1 ||
				_type == DiceSlotType.REQUIRE2 ||
				_type == DiceSlotType.REQUIRE3 ||
				_type == DiceSlotType.REQUIRE4 ||
				_type == DiceSlotType.REQUIRE5 ||
				_type == DiceSlotType.REQUIRE6){
			conditionalslots = true;
		}
		
		if (Reunion.checkcoinmodeequipment(this)){
			//This doesn't work, why doesn't this work
			if (_type == DiceSlotType.MAX2 ||	_type == DiceSlotType.MIN5){
				conditionalslots = true;
			}
		}
	}
	
	public function slotcheck(d:Dice, s:Int):Bool{
		//Is it ok to assign dice d to this slot, s?
		//This is checking validity, not collision
		return Game.slotcheckvalue(d.value, slots[s]);
	}
	
	public function assigndicetoshockedslot(d:Dice, slot:Int = -1, lerp:Float = 0){
		for (i in 0 ... shocked_assigneddice.length){
			if(slot == i || slot == -1){
				var slotready:Bool = (shocked_assigneddice[i] == null);
				if (shocked_slots[i] == DiceSlotType.COUNTDOWN){
					slotready = (shocked_remainingcountdown > 0);
				}
				
				if (slotready){
					if (shocked_slots[i] == DiceSlotType.COUNTDOWN){
						d.assignedposition = i;
						d.highlight = 0;
						if(lerp == 0){
							d.x = x + shocked_slotpositions[i].x + Game.dicexoffset;
							d.y = y + shocked_slotpositions[i].y + Game.diceyoffset;
							d.inlerp = false;
						}else{
							d.inlerp = true;
							Actuate.tween(d, lerp, {
								  x: x + shocked_slotpositions[i].x + Game.dicexoffset, 
									y: y + shocked_slotpositions[i].y + Game.diceyoffset})
								.onComplete(function(d:Dice){d.inlerp = false; }, [d]);
						}
						d.assigned = this;
						
						d.consumedice();
						
						reducecountdownby += d.value;
						reducecountdowndelay = 0;
						
						return;
					}else	if (Game.slotcheckvalue(d.value, shocked_slots[i])){
						d.assignedposition = i;
						d.highlight = 0;
						if(lerp == 0){
							d.x = x + shocked_slotpositions[i].x + Game.dicexoffset;
							d.y = y + shocked_slotpositions[i].y + Game.diceyoffset;
							d.inlerp = false;
						}else{
							d.inlerp = true;
							d.inlerp = true;
							Actuate.tween(d, lerp, {
								x: x + shocked_slotpositions[i].x + Game.dicexoffset, 
								y: y + shocked_slotpositions[i].y + Game.diceyoffset})
								.onComplete(function(d:Dice){d.inlerp = false; }, [d]);
						}
						d.assigned = this;
						
						shocked_assigneddice[i] = d;
						return;
					}
				}
		  }
		}
	}
	
	public function assigndice(d:Dice, slot:Int = -1, lerp:Float = 0){		
		invalidatecache();
		
		for (i in 0 ... assigneddice.length){
			if(slot == i || slot == -1){
				var slotready:Bool = (assigneddice[i] == null);
				if (slots[i] == DiceSlotType.COUNTDOWN){
					slotready = (remainingcountdown > 0);
				}
				
				if (slotready){
					if (slots[i] == DiceSlotType.COMBINATION){
						var combinationacceptsdice:Int = Combination.acceptsdice(d, this);
						if (combinationacceptsdice != -1){
							Combination.playsound(this);
							Combination.assigndicevalue(d, this, combinationacceptsdice);
							
							d.assignedposition = i;
							d.highlight = 0;
							d.assigned = this;
							
							if (equippedby == null) equippedby = Game.fixequippedbyfield(this);
							if (equippedby != null){
								Script.callechoscripts_countdownreduce(equippedby, this);
							}
							
							if(lerp == 0 || ControlMode.gamepad()){
								d.inlerp = false;
								d.fastconsumedice();
							}else{
								if (d.touch != null){
									d.inlerp = true;
									Actuate.tween(d, lerp, {
										x: d.touch.x - (20 * 6) - Game.dicexoffset, 
										y: d.touch.y - (20 * 6) - Game.diceyoffset})
										.onComplete(function(d:Dice){d.inlerp = false; }, [d]);
									d.consumedice();
								}else{
									//This shouldn't actually happen, but just in case
									d.inlerp = false;     
									d.fastconsumedice();
								}
							}
						}
						
						return;
					}else if (slots[i] == DiceSlotType.WITCH){
						if(Spellbook.matchingspell(d.basevalue) && Spellbook.spells_availablethisturn[d.basevalue - 1]){
							Spellbook.adddice(d);
							
							d.assignedposition = i;
							d.highlight = 0;
							d.assigned = this;
							if(lerp == 0 || ControlMode.gamepad()){
								d.inlerp = false;
								d.fastconsumedice();
							}else{
								if (d.touch != null){
									d.inlerp = true;
									Actuate.tween(d, lerp, {
										x: d.touch.x - (20 * 6) - Game.dicexoffset, 
										y: d.touch.y - (20 * 6) - Game.diceyoffset})
										.onComplete(function(d:Dice){d.inlerp = false; }, [d]);
									d.consumedice();
								}else{
									//This shouldn't actually happen, but just in case
									d.inlerp = false;     
									d.fastconsumedice();
								}
							}
						}
						
						return;
					}else	if (slots[i] == DiceSlotType.COUNTDOWN){
						if (LadyLuckCommands.active){
							LadyLuckCommands.check("reducecountdown", [this], [d]);
						}
						d.assignedposition = i;
						d.highlight = 0;
						if(lerp == 0){
							d.x = x + slotpositions[i].x + Game.dicexoffset;
							d.y = y + slotpositions[i].y + Game.diceyoffset;
							d.inlerp = false;
						}else{
							d.inlerp = true;
							Actuate.tween(d, lerp, {
								  x: x + slotpositions[i].x + Game.dicexoffset, 
									y: y + slotpositions[i].y + Game.diceyoffset})
								.onComplete(function(d:Dice){d.inlerp = false; }, [d]);
						}
						d.assigned = this;
						
						//Alternate Re-Equip Next check
						var altreequipnextcheck:Bool = false;
						if (equippedby != null){
							if (equippedby.hasstatus(Status.ALTERNATE + Status.REEQUIPNEXT)){
								var dexterity:StatusEffect = equippedby.getstatus(Status.ALTERNATE + Status.REEQUIPNEXT);
								dexterity.value--;
								dexterity.displayvalue = dexterity.value;
								if (dexterity.value <= 0){
									equippedby.removestatus(Status.ALTERNATE_REEQUIPNEXT);
								}
								
								altreequipnextcheck = true;
							}
						}
						
						if (altreequipnextcheck){
							//Apply Alternate Re-Equip Next for countdowns here! (this used to be called "dexterity")
							var newdice:Dice = new Dice(d.x, d.y);
							newdice.owner = equippedby;
							newdice.copyfrom(d);
							equippedby.dicepool.push(newdice);
						}
						
						//Keep a history of dice used on this card, and also whether or not we've used
						//an alternate burning dice on this card.
						var tdice:Dice = new Dice();
						tdice.basevalue = d.basevalue;
						tdice.alternateburn = d.alternateburn;
						dicehistory.push(tdice);
						if (tdice.alternateburn){
							alternateburningcountdownslot = true;
							availablenextturn = false;
							unavailabletext = displayname;
							unavailablemodifier = namemodifier;
							unavailabledetails = ["Unavailable (Burn?)"];
						}
						
						if(equippedby != null){
							Script.callechoscripts_countdownreduce(equippedby, this);
						}
						
						d.consumedice();
						
						if (Rules.enemycountdownrate != 1.0){
							var countdownspeed:Float = 1.0;
							
							if (equippedby != null){
								if (!equippedby.isplayer){
									countdownspeed = Rules.enemycountdownrate;
								}
							}
							
							reducecountdownby += Std.int(d.value * countdownspeed);
						}else{
							reducecountdownby += d.value;
						}
						reducecountdowndelay = 0;
						
						return;
					}else	if (slotcheck(d, i)){
						d.assignedposition = i;
						d.highlight = 0;
						if(lerp == 0){
							d.x = x + slotpositions[i].x + Game.dicexoffset;
							d.y = y + slotpositions[i].y + Game.diceyoffset;
							d.inlerp = false;
						}else{
							d.inlerp = true;
							Actuate.tween(d, lerp, {
								x: x + slotpositions[i].x + Game.dicexoffset, 
								y: y + slotpositions[i].y + Game.diceyoffset})
								.onComplete(function(d:Dice){d.inlerp = false; }, [d]);
						}
						d.assigned = this;
						
						assigneddice[i] = d;
						return;
					}
				}
		  }
		}
	}
	
	public function destroydice(){
		//Destroy any dice assigned to this equipment (i.e. don't re-add them to the dice pool)
		for (i in 0 ... assigneddice.length){
			if(assigneddice[i] != null){
				assigneddice[i].assigned = null;
				Game.player.dicepool.remove(assigneddice[i]);
				Game.monster.dicepool.remove(assigneddice[i]);
				assigneddice[i] = null;
			}
		}
	}
	
	public function removedice(?d:Dice){
		invalidatecache();
		
		if (d == null){
			for (i in 0 ... assigneddice.length){
				if(assigneddice[i] != null){
					assigneddice[i].assigned = null;
					assigneddice[i] = null;
				}
			}
			
			for (i in 0 ... shocked_assigneddice.length){
				if(shocked_assigneddice[i] != null){
					shocked_assigneddice[i].assigned = null;
					shocked_assigneddice[i] = null;
				}
			}
			return;
		}else{
			for (i in 0 ... assigneddice.length){
				if (assigneddice[i] != null){
					if (assigneddice[i] == d){
						d.assigned = null;
						assigneddice[i] = null;
						return;
					}
				}
			}
			
			for (i in 0 ... shocked_assigneddice.length){
				if (shocked_assigneddice[i] != null){
					if (shocked_assigneddice[i] == d){
						d.assigned = null;
						shocked_assigneddice[i] = null;
						return;
					}
				}
			}
		}
		
		//Do I need this? Maybe not. Probably gonna regret this!
		d.assigned = null;
		//throw("Trying to removing dice from " + name + ", but it's not assigned here.");
	}
	
	public var backgroundcol:Int;
	public var bordercol:Int;
	public var foregroundcol:Int;
	public var highlightdicecol:Int;
	public var highlighttextcol:Int;
	public var currentheight:Float;
	
	//Returns "true" if generation code stops after this step
	public function downgrade():Bool{
		equipmentpanel.dispose();
		equipmentpanel = null;
		
		var create_weakened_version_of_upgraded_equipment:Bool = false;
		var upgraded_version_modifies_the_countdown:Int = 0;
		
		if (upgraded){
			var unupgraded_equiptemplate:EquipmentTemplate = Gamedata.getequipmenttemplate(rawname);
			
			if (Gamedata.completeequipmentlist.indexOf(rawname + "_weakened") > -1){
			  //If this equipment is upgraded, and a "_weakened" version exists, then...
				create_weakened_version_of_upgraded_equipment = true;
			}else if (unupgraded_equiptemplate.upgradetype == "threequartercountdown" || unupgraded_equiptemplate.upgradetype == "halfcountdown"){
				upgraded_version_modifies_the_countdown = maxcountdown;
			}
		}
		
		if (weakentype == ""){
			if (upgraded){
				weakentype = Gamedata.getequipmenttemplate(rawname).weakentype;
			}
		}
		
		if (create_weakened_version_of_upgraded_equipment){
			//Special case! Downgrade to the special equipment_weakened equipement.
			var oldequip:Equipment = copy();
			var oldcombination:String = Combination.getstring(this);
			
			create(rawname_beforesubstitution + "_weakened", false, false);
			x = oldequip.x;
			y = oldequip.y;
			charge = oldequip.charge;
			name = rawname;
			namemodifier = "-";
			weakentype = "";
			weakened = true;
			originallyupgraded = true;
			
			timesused = oldequip.timesused;
			totalusesremaining = oldequip.totalusesremaining;
			countdown = oldequip.countdown;
			reducecountdownby = oldequip.reducecountdownby;
			reducecountdowndelay = oldequip.reducecountdowndelay;
			remainingcountdown = clampremainingcountdown(oldequip.remainingcountdown, oldequip.maxcountdown, maxcountdown);
			
			if (hastag("combination")){	setvar("combination", oldcombination); }
			
			if (equippedby != null){
				if (equippedby.layout == EquipmentLayout.DECK || Rules.bigequipmentmode) if (size != 2) resize(2);
			}
			
			if(equipmentpanel == null){
				equipmentpanel = new EquipmentPanel();
			}
			return true;
		}else	if (weakentype != ""){
			var oldequip:Equipment = copy();
			if (upgraded){
				create(rawname_beforesubstitution, false, false);
				x = oldequip.x;
				y = oldequip.y;
				charge = oldequip.charge;
				timesused = oldequip.timesused;
				totalusesremaining = oldequip.totalusesremaining;
				originallyupgraded = true;
				
				if (upgraded_version_modifies_the_countdown > 0){
					remainingcountdown = clampremainingcountdown(oldequip.remainingcountdown, oldequip.maxcountdown, upgraded_version_modifies_the_countdown);	
				}else{
					remainingcountdown = clampremainingcountdown(oldequip.remainingcountdown, oldequip.maxcountdown, maxcountdown);	
				}
			}
			
			if (equippedby != null){
				if (equippedby.layout == EquipmentLayout.DECK || Rules.bigequipmentmode) if (size != 2) resize(2);
			}
			
			weakened = true;
			name = rawname;
			namemodifier = "-";				
			switch(weakentype){
				case "changetotal9":	needstotal = 9;
				case "changetotal10":	needstotal = 10;
				case "changetotal11":	needstotal = 11;
				case "changetotal12":	needstotal = 12;
				case "burnsparedice":
				  for (i in 0 ... slots.length){
						if (Game.diceslotissparedice(slots[i])){
							if (assigneddice[i] != null){
								if (!assigneddice[i].burn){
									assigneddice[i].burnnow();
								}
							}
						}
					}
			  case "removereusable":
				  reuseable = 0;
					usesleft = 0;
					reuseableanimation = 0;
					tempreuseableequipment = [];
					overwritefinalline = "";
					
					fulldescription = S.removefromright(fulldescription, "|[gray](Reuseable)".length);
				case "noeffect":
					script = "";
					scriptrunner = null;
					overwritefinalline = "";
					
					fulldescription = "No effect";
				case "doublerequirements":
					addslots(slots[0]);
					assigneddice = [];
					for (i in 0 ... slots.length){
						assigneddice.push(null);
					}
					arrangeslots();
				case "decreaserange":
					conditionalslots = false;
					for (i in 0 ... slots.length){
						if (slots[i] == DiceSlotType.MAX2){
							slots[i] = DiceSlotType.REQUIRE1;
							conditionalslots = true;
						}else if (slots[i] == DiceSlotType.MAX3){
							slots[i] = DiceSlotType.MAX2;
						}else if (slots[i] == DiceSlotType.MAX4){
							slots[i] = DiceSlotType.MAX3;
						}else if (slots[i] == DiceSlotType.MAX5){
							slots[i] = DiceSlotType.MAX4;
						}else if (slots[i] == DiceSlotType.MIN5){
							slots[i] = DiceSlotType.REQUIRE6;
							conditionalslots = true;
						}else if (slots[i] == DiceSlotType.MIN4){
							slots[i] = DiceSlotType.MIN5;
						}else if (slots[i] == DiceSlotType.MIN3){
							slots[i] = DiceSlotType.MIN4;
						}else if (slots[i] == DiceSlotType.MIN2){
							slots[i] = DiceSlotType.MIN3;
						}else if (slots[i] == DiceSlotType.NORMAL){
							slots[i] = DiceSlotType.MAX5;
						}
					}
				case "complicate":
					for (i in 0 ... slots.length){
						if (slots[i] == DiceSlotType.NORMAL){
							slots[i] = DiceSlotType.MAX3;
						}else if (slots[i] == DiceSlotType.EVEN){
							slots[i] = DiceSlotType.REQUIRE6;
							conditionalslots = true;
							arrangeslots();
						}else if (slots[i] == DiceSlotType.ODD){
							slots[i] = DiceSlotType.REQUIRE5;
							conditionalslots = true;
							arrangeslots();
						}else if (slots[i] == DiceSlotType.MIN2){
							slots[i] = DiceSlotType.REQUIRE6;
							conditionalslots = true;
							arrangeslots();
						}else if (slots[i] == DiceSlotType.MIN3){
							slots[i] = DiceSlotType.REQUIRE6;
							conditionalslots = true;
							arrangeslots();
						}else if (slots[i] == DiceSlotType.MIN4){
							slots[i] = DiceSlotType.REQUIRE6;
							conditionalslots = true;
							arrangeslots();
						}else if (slots[i] == DiceSlotType.MIN5){
							slots[i] = DiceSlotType.REQUIRE6;
							conditionalslots = true;
							arrangeslots();
						}else if (slots[i] == DiceSlotType.MAX5){
							slots[i] = DiceSlotType.MAX3;
						}else if (slots[i] == DiceSlotType.MAX4){
							slots[i] = DiceSlotType.MAX2;
						}else if (slots[i] == DiceSlotType.MAX3){
							slots[i] = DiceSlotType.MAX2;
						}else if (slots[i] == DiceSlotType.MAX2){
							slots[i] = DiceSlotType.MAX1;
						}else if (slots[i] == DiceSlotType.MIN2){
							slots[i] = DiceSlotType.MIN4;
						}else if (slots[i] == DiceSlotType.RANGE23){
							slots[i] = DiceSlotType.REQUIRE2;
						}else if (slots[i] == DiceSlotType.RANGE24){
							slots[i] = DiceSlotType.REQUIRE3;
						}else if (slots[i] == DiceSlotType.RANGE25){
							slots[i] = DiceSlotType.RANGE34;
						}else if (slots[i] == DiceSlotType.RANGE34){
							slots[i] = DiceSlotType.REQUIRE3;
						}else if (slots[i] == DiceSlotType.RANGE35){
							slots[i] = DiceSlotType.REQUIRE4;
						}else if (slots[i] == DiceSlotType.RANGE45){
							slots[i] = DiceSlotType.REQUIRE4;
						}
					}
				case "change_power", "change_function":
					//Keep the countdown intact
					var oldequip:Equipment = copy();
					overwritefinalline = "";
					
					var keepcountdown:Bool = false;
					if (hastag("keepcountdown")) keepcountdown = true;
					var oldcombination:String = Combination.getstring(this);
					/*
					 * This fix is too dangerous to apply before Reunion, commenting it out
					var oldvariables:Map<String, Dynamic> = new Map<String, Dynamic>();
					if(gamevar != null){
						for (key in gamevar.keys()){
							oldvariables.set(key, gamevar.get(key));
						}
					}*/
					
					var reallyoriginallyupgraded:Bool = originallyupgraded;
					if (name_beforesubstitution != name){
						create(rawname_beforesubstitution + "_downgraded", false, false);
					}else{
						create(rawname + "_downgraded", false, false);
					}
					name = rawname;
					namemodifier = "-";
					weakentype = "";
					weakened = true;
					
					x = oldequip.x;
					y = oldequip.y;
					charge = oldequip.charge;
					timesused = oldequip.timesused;
					totalusesremaining = oldequip.totalusesremaining;
					originallyupgraded = reallyoriginallyupgraded;
					if (keepcountdown) maxcountdown = oldequip.maxcountdown;
					countdown = oldequip.countdown;
					reducecountdownby = oldequip.reducecountdownby;
					reducecountdowndelay = oldequip.reducecountdowndelay;
					if (keepcountdown) {
						remainingcountdown = oldequip.remainingcountdown;
					}else{
						remainingcountdown = clampremainingcountdown(oldequip.remainingcountdown, oldequip.maxcountdown, maxcountdown);
					}
					
					if (hastag("combination")){
						setvar("combination", oldcombination); 
					}
					
					//Copy equipment variables to weakened version
					//gamevar = oldvariables;
					
					if (equippedby != null){
						if (equippedby.layout == EquipmentLayout.DECK || Rules.bigequipmentmode) if (size != 2) resize(2);
					}
					
					if(equipmentpanel == null){
						equipmentpanel = new EquipmentPanel();
					}
					return true;
				default:
					throw("Error: Downgrade type is \"" + weakentype + "\", but I don't know what to do with that");
			}
			weakentype = "";
		}
		
		if (equippedby != null){
			if (equippedby.layout == EquipmentLayout.DECK || Rules.bigequipmentmode) if (size != 2) resize(2);
		}
			
		if(equipmentpanel == null){
			equipmentpanel = new EquipmentPanel();
		}
		return false;
	}
	
	public function unweaken(fromdeck:Bool = false){
		if (weakened){
			equipmentpanel.dispose();
			
			var oldcombination:String = getvar("combination");
			/*
			var oldvariables:Map<String, Dynamic> = new Map<String, Dynamic>();
			if(gamevar != null){
				for (key in gamevar.keys()){
					oldvariables.set(key, gamevar.get(key));
				}
			}*/
			
			var keepcountdown:Bool = false;
			if (hastag("keepcountdown")) keepcountdown = true;
			
			var c:Equipment = copy();
			
			if (c.originallyupgraded){
				create(rawname_beforesubstitution, true, false, fromdeck);
			}else{
				create(rawname_beforesubstitution, false, false, fromdeck);
				namemodifier = "";
			}
			
			x = c.x;
			y = c.y;
			charge = c.charge;
			
			timesused = c.timesused;
			totalusesremaining = c.totalusesremaining;
			
			reducecountdownby = c.reducecountdownby;
			reducecountdowndelay = c.reducecountdowndelay;
			
			if (keepcountdown){
				countdown = c.countdown;
				remainingcountdown = c.remainingcountdown;
				maxcountdown = c.maxcountdown;
			}else{
				if (c.countdown < countdown){
					countdown = c.countdown;
				}
				
				//Unweakening countdowns needs to be done carefully: the value should only change if the unweakening causes the value to
				//be higher than what it should be
				remainingcountdown = c.remainingcountdown;
				if (remainingcountdown > maxcountdown){
					remainingcountdown = maxcountdown;
				}
			}
			
			//Copy equipment variables to weakened version
			//gamevar = oldvariables;
			
			if (hastag("combination")){	setvar("combination", oldcombination); }
			
			if (equippedby != null){
				if (equippedby.layout == EquipmentLayout.DECK || Rules.bigequipmentmode) if (size != 2) resize(2);
			}
		}
	}
	
	public function copy():Equipment{
		var c:Equipment = new Equipment(name_beforesubstitution, upgraded, weakened);
		
		c.x = x;
		c.y = y;
		c.timesused = timesused;
		c.totalusesremaining = totalusesremaining;
		c.fulldescription = fulldescription;
		c.overwritefinalline = overwritefinalline;
		c.name = name;
		c.namemodifier = namemodifier;
		c.originallyupgraded = originallyupgraded;
		c.countdown = countdown;
		c.reducecountdownby = reducecountdownby;
		c.remainingcountdown = remainingcountdown;
		c.reducecountdowndelay = reducecountdowndelay;
		c.equippedby = equippedby;
		c.charge = charge;
		c.castdirection = castdirection;
		c.temporary_thisturnonly = temporary_thisturnonly;
		if (initialpos == null) initialpos = new Point(x, y);
		c.initialpos = initialpos.clone();
		if (finalpos == null) finalpos = new Point(x, y);
		c.finalpos = finalpos.clone();
		c.tags = []; for (i in 0 ... tags.length) c.tags.push(tags[i]);
		
		//Check that the slots on the copy and the original equipment match. These can
		//diverge if we've run changeslots() on the original equipment, which causes
		//some problems for reuseable equipment. Fix them if they don't match.
		var slotsmatch:Bool = true;
		if (c.slots.length != slots.length){
			slotsmatch = false;
		}else{
			for (i in 0 ... slots.length){
				if (slots[i] != c.slots[i]) slotsmatch = false;
			}
		}
		if (!slotsmatch) c.changeslots(getslots());
		
		if (c.size != size){
			c.resize(size);
		}
		
		return c;
	}
	
	public function do_shock_returndice(){
		if(shocked_returndice){
			if (equippedby == null) equippedby = Game.fixequippedbyfield(this);
			if (equippedby != null){
				var newdice:Array<Dice> = equippedby.rolldice(shocked_assigneddice.length, equippedby.isplayer?Gfx.BOTTOM:Gfx.TOP, 0, 0, "diceroll", true);
				for (i in 0 ... shocked_assigneddice.length){
					if (shocked_assigneddice[i] != null){
						newdice[i].basevalue = shocked_assigneddice[i].basevalue;
						newdice[i].blind = shocked_assigneddice[i].blind;
					}else{
						trace("shocked_assigneddice[" + i + "] is null?");
					}
				}
				
				//Check for counterspell
				equippedby.checkfordicecounter(newdice);
				//run onrolldice script hooks
				equippedby.runonrolldicescripts(newdice);
			}
		}
		shocked_returndice = false;
	}

	public function clearshock(){
		if (shockedsetting > 0) {
			unshockingtimer = 0;
			shockedtype = "NORMAL";
			shockedsetting = 0;
			shockedcol = Pal.BLACK;
			shockedtext = "";
			shocked_showtitle = true;
			shocked_needstotal = 0;
			do_shock_returndice();
			for (i in 0 ... shocked_assigneddice.length){
				if(shocked_assigneddice[i] != null){
					shocked_assigneddice[i].assigned = null;
				}
			}
			var removesilence:Bool = false;
			
			if (equippedby == null) equippedby = Game.fixequippedbyfield(this);
			if (equippedby != null){
				if (equippedby.hasstolencard){
					if (equippedby.stolencard == this){
						removesilence = true;
					}
				}
			}
			
			if (skillcard != "") removesilence = true;
			AudioControl.play("remove_shock_from_equipment");
			if (removesilence){
				animate("removesilence");
			}else{
				flashtime = 0.2 / BuildConfig.speed;
			}
			
			for (s in equippedby.status) s.runscript("onshockrelease", 0, this);
		}
	}
	
	public function update(){
		var countdownspeed:Float = 1.0;
		
		if(Rules.enemycountdownrate != 1.0){
			if (equippedby != null){
				if (!equippedby.isplayer){
					countdownspeed = Rules.enemycountdownrate;
				}
			}
		}
		
		if (shockedsetting > 0){
			if(unshockingtimer != 0){
				unshockingtimer -= Game.deltatime;
				if (unshockingtimer <= 0){
					clearshock();
				}
			}
			
			if (shocked_countdown > 0){
				if (reducecountdownby > 0){
					reducecountdowndelay -= Game.deltatime * BuildConfig.speed * countdownspeed;
					
					if (reducecountdowndelay <= 0){
						var countdownslot:Int = 0;
						for (i in 0 ... shocked_slots.length){
							if (shocked_slots[i] == DiceSlotType.COUNTDOWN){
								countdownslot = i;
							}
						}
						reducecountdowndelay = 0.12 + (0.12 / reducecountdownby);
						
						//TO DO?
						//shakeslot(countdownslot, 0, -3);
						reducecountdownby--;
						if (shocked_remainingcountdown > 3){
							AudioControl.play("countdowntick_above3");
						}else if (shocked_remainingcountdown == 3){
							AudioControl.play("countdowntick_3");
						}else if (shocked_remainingcountdown == 2){
							AudioControl.play("countdowntick_2");
						}else if (shocked_remainingcountdown <= 1){
							AudioControl.play("countdowntick_1");
						}
						shocked_remainingcountdown--;
						if (shocked_remainingcountdown <= 0){
							shocked_remainingcountdown = 0;
							reducecountdownby = 0;
							
							//Unshock now, if ready!
							AudioControl.play("remove_shock_from_equipment");
							Combat.unshockequipmentifready(this);
						}
					}
				}
			}
		}else{
			if (countdown > 0){
				if (reducecountdownby > 0){
					reducecountdowndelay -= Game.deltatime * BuildConfig.speed * countdownspeed;
					
					if (reducecountdowndelay <= 0){
						var countdownslot:Int = 0;
						for (i in 0 ... slots.length){
							if (slots[i] == DiceSlotType.COUNTDOWN){
								countdownslot = i;
							}
						}
						reducecountdowndelay = 0.12 + (0.12 / reducecountdownby);
						
						shakeslot(countdownslot, 0, -3);
						reducecountdownby--;
						if (remainingcountdown > 3){
							AudioControl.play("countdowntick_above3");
						}else if (remainingcountdown == 3){
							AudioControl.play("countdowntick_3");
						}else if (remainingcountdown == 2){
							AudioControl.play("countdowntick_2");
						}else if (remainingcountdown <= 1){
							AudioControl.play("countdowntick_1");
						}
						remainingcountdown--;
						if (remainingcountdown <= 0){
							remainingcountdown = 0;
							reducecountdownby = 0;
						}
						
						invalidatecache();
						
						Combat.resetstolencardcountdown(this);
						Combat.resetjesterdeckcountdown(this);
						Combat.resetinventorcountdown(this);
					}
				}
			}
		}
		
		if (animation.length > 0){
			//Run the first animation
			for (i in 0 ... animation.length){
				if(animation[i] != null){
					if (!animation[i].active && !animation[i].finished){
						animation[i].start();
					}
					
					if (animation[i].active){
						animation[i].update();
					}
				}
			}
			
			if (animation.length > 0){
				if (animation[0].finished){
					animation.shift();
					if (onanimatecomplete != null){
						onanimatecomplete(onanimatecomplete_selectedslot, onanimatecomplete_actor, onanimatecomplete_equipment);
						onanimatecomplete = null;
					}
				}
			}
		}
		
		if (flashtime > 0){
			flashtime -= Game.deltatime;
			if (flashtime <= 0){
				flashtime = 0;
			}
		}
		
		if (reuseableanimation > 0){
			reuseableanimation -= Game.deltatime;
			if (reuseableanimation <= 0){
				reuseableanimation = 0;
			}
		}
		
		if (equippedby != null && equippedby.isplayer) {
			var targetalpha:Float = 1.0;
			if (ControlMode.gamepad()) {
				if (Combat.flee_showprompt || LimitBreakPrompt.showing) {
					targetalpha = 0.5;
				} else if (skillcard == "robot_request" && Combat.gamepad_dicemode) {
					if (Game.player.hasrequestdice()) {
						targetalpha = 1.0;
					} else {
						targetalpha = 0.5;
					}
				} else {
					if (Combat.gamepad_dicemode || Combat.gamepad_buttonmode) {
						if (Combat.gamepad_selectedequipment == this) {
							targetalpha = 1.0;
						} else {
							targetalpha = 0.5;
						}
					}
				}
			}
			
			if (gamepadalpha > targetalpha) {
				gamepadalpha = gamepadalpha + (targetalpha - gamepadalpha) * 0.25 - 0.15;
				if (gamepadalpha < targetalpha) {
					gamepadalpha = targetalpha;
				}
			} else if (gamepadalpha < targetalpha) {
				if (this == Combat.gamepad_selectedequipment) {
					gamepadalpha = gamepadalpha + (targetalpha - gamepadalpha) * 0.25 + 0.15;
				} else {
					//gamepadalpha = gamepadalpha + (targetalpha - gamepadalpha) * 0.04 + 0.01;
					gamepadalpha = gamepadalpha + (targetalpha - gamepadalpha) * 0.25 + 0.15;
				}
				
				if (gamepadalpha > targetalpha) {
					gamepadalpha = targetalpha;
				}
			}
		} else {
			gamepadalpha = 1.0;
		}
	}
	
	public function drawwithoutskills(){
		if (!Screen.enabledisplay_cards) return;
		
		if (show){
			if (blackedout){
				equipmentpanel.blackout(this, x, y, equipalpha * gamepadalpha);
			}else{
				Locale.gamefontsmall.change();
				
				Game.hideskills = true;
				render( -1000, -1000, true, equipalpha * gamepadalpha);
				Game.hideskills = false;
				
				Locale.gamefont.change();
			}
		}

		if (cursedimage > 0){
			equipmentpanel.cursedimage(this, tx, ty, useglitch, function() {
				cursedimage = 0;
				useglitch = false;
			});
		}
		
		if (tempreuseableequipment.length > 0){
			for(t in tempreuseableequipment){
				t.draw();
			}
		}
	}
	
	public function draw(){
		if (!Screen.enabledisplay_cards) return;
		
		if ((show || cursedimage > 0) && onscreen()){
			if (show) {
				if (blackedout){
					equipmentpanel.blackout(this, x, y, equipalpha * gamepadalpha);
				}else{
					Locale.gamefontsmall.change();
					
					render( -1000, -1000, true, equipalpha * gamepadalpha);
					
					Locale.gamefont.change();
				}
			}
			
			if (cursedimage > 0){
				equipmentpanel.cursedimage(this, tx, ty, useglitch, function() {
					cursedimage = 0;
					useglitch = false;
				});
			}
		}
		
		if (tempreuseableequipment.length > 0){
			for(t in tempreuseableequipment){
				t.draw();
			}
		}
	}
	
	public function invalidatecache(){
		equipmentpanel.cacheisdirty = true;
	}

	public function remove(){
		equipmentpanel.dispose();
	}

	public function canuseslot(slot:Int) : Bool {
		if (slot < assigneddice.length && assigneddice[slot] == null) {
			switch (slots[slot]) {
				case DiceSlotType.LOCKED2: return false;
				case DiceSlotType.LOCKED3: return false;
				case DiceSlotType.LOCKED4: return false;
				case DiceSlotType.LOCKED5: return false;
				case DiceSlotType.LOCKED6: return false;
				case DiceSlotType.LOCKED7: return false;
				case DiceSlotType.FREE1: return false;
				case DiceSlotType.FREE2: return false;
				case DiceSlotType.FREE3: return false;
				case DiceSlotType.FREE4: return false;
				case DiceSlotType.FREE5: return false;
				case DiceSlotType.FREE6: return false;
				case DiceSlotType.SKILL: return false;
				default: return true;
			}
		}
		
		return false;
	}
	
	public function getgamepadslot(_dice:Dice) : Point {
		var hoverslot:Point = null;
		
		if (shockedsetting == 0 && stolencard && equippedby.stolencard.slotsfree > 0) {
			for (j in 0 ... equippedby.stolencard.slots.length) {
				if (equippedby.stolencard.canuseslot(j)) {
					hoverslot = equippedby.stolencard.slotpositions[j];
					break;
				}
			}
		} else if (shockedsetting == 0 && slotsfree > 0) {
			for (j in 0 ... slots.length) {
				if (canuseslot(j)) {
					if (slots[j] == DiceSlotType.COMBINATION){
						if (_dice != null && (Combination.acceptsdice(_dice, this) > -1)){
							hoverslot = slotpositions[j];
							break;
						} else {
							if (hoverslot == null) {
								hoverslot = slotpositions[j];
							}
						}
					}else{
						if (_dice != null && Game.slotcheckvalue(_dice.value, slots[j])) {
							hoverslot = slotpositions[j];
							break;
						} else {
							if (hoverslot == null) {
								hoverslot = slotpositions[j];
							}
						}
					}
				}
			}
		} else if (shockedsetting > 0 && shockedslotsfree > 0) {
			for (j in 0 ... shocked_slots.length) {
				if (shocked_assigneddice[j] == null) {
					hoverslot = shocked_slotpositions[j];
					break;
				}
			}
		}
		
		return hoverslot;
	}
	
	@:access(haxegon.Scene)
	public function showgamepadhighlight() : Bool {
		if (!ControlMode.gamepad()) {
			return false;
		}
		
		// Okay, here we go. Some powerful hacks for highlighting equipment in selection screens.
		if (ButtonGamepadNavigation.currentscene() == LevelUpScreen) {
			if (ButtonGamepadNavigation.activebutton != null && LevelUpScreen.state != "finderskeepers") {
				return (ButtonGamepadNavigation.activebutton.x > x && ButtonGamepadNavigation.activebutton.x <= x + width);
			}
			return false;
		} else if (ButtonGamepadNavigation.currentscene() == Shopstate) {
			if (ButtonGamepadNavigation.activebutton != null) {
				return (ButtonGamepadNavigation.activebutton.x > x && ButtonGamepadNavigation.activebutton.x <= x + width);
			}
			return false;
		} else if (ButtonGamepadNavigation.currentscene() == ViewDeck) {
			if (ViewDeck.viewtype != "delete_complete") {
				var cardidx:Int = Std.int(Math.round(ViewDeck.actualscrollposition));
				if (cardidx >= 0 && cardidx < Deck.mastercardlist.length) {
					return (Deck.mastercardlist[cardidx].equipment == this);
				}
			}
			return false;
		}
		
		if (Combat.selectspellslotmode || !Combat.allowgamepad() || !Combat.playerequipmentready || Combat.preventfurtheractions) {
			return false;
		}
		
		if (Combat.gamepad_movementgracetime > 0) {
			return false;
		}
		
		if (Combat.gamepad_selectedequipment == null) {
			return false;
		}

		if (Combat.gamepad_selectedequipment != null && Combat.gamepad_selectedequipment.stolencard) {
			return Combat.gamepad_selectedequipment.equippedby != null && Combat.gamepad_selectedequipment.equippedby.stolencard == this;
		} else {
			return Combat.gamepad_selectedequipment == this;
		}
	}
	
	public function hasmultiplebuttons() : Bool {
		if (skillcard == "robot_request") {
			return true;
		}
		
		if (skillcard == "stockpile") {
			return true;
		}
		
		if (skillcard == "robot_calculate") {
			return (Game.player.roll_jackpot == 2);
		}
		
		if (shockedsetting >= 1) return false; //If silenced or shocked, then don't consider multiple buttons
		
		return skills.length > 1;
	}
	
	public function render(altxpos:Float, altypos:Float, interactive:Bool, alpha:Float){
		//This is a very hacky fix that you should probably try to improve before release
		if (Reunion.checkcoinmodeequipment(this)){
			for(i in 0 ... slots.length){
				if (slots[i] == DiceSlotType.MAX2 || slots[i] == DiceSlotType.MIN5){
					if (!conditionalslots){
						trace("render override activated");
						conditionalslots = true;
						arrangeslots();
					}
				}
			}
		}
		
		if(lastlocale != Locale.currentlanguage) {
			reloadtranslations();
			lastlocale = Locale.currentlanguage;
		}

		if (altxpos == -1000){
			tx = Std.int(x);
			ty = Std.int(y);
		}else{
			tx = Std.int(altxpos);
		  ty = Std.int(altypos);
		}
		
		tx += shakex * Random.int( -2 * 6, 2 * 6);
		ty += shakey * Random.int( -2 * 6, 2 * 6);
		
		if (flashtime > 0){
			tx += Random.int( -2 * 6, 2 * 6);
			ty += Random.int( -2 * 6, 2 * 6);
		}
		
		// Gamepad highlight
		if (showgamepadhighlight()) {
			var gamepadcursor:HaxegonSprite = null;
			if (this.size == 2) {
				if (gamepadcursor_large == null) {
					gamepadcursor_large = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_tall");
					gamepadcursor_large.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171 + (1216 - 655));
				}
				gamepadcursor = gamepadcursor_large;
			} else if (this.y + 0.5*this.height < Screen.heightmid) {
				if (gamepadcursor_small1 == null) {
					gamepadcursor_small1 = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_small");
					gamepadcursor_small1.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171);
				}
				gamepadcursor = gamepadcursor_small1;
			} else {
				if (gamepadcursor_small2 == null) {
					gamepadcursor_small2 = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_small");
					gamepadcursor_small2.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171);
				}
				gamepadcursor = gamepadcursor_small2;
			}
			
			gamepadcursor.x = tx - 25;
			gamepadcursor.y = ty - 42;
			
			if (skillcard == "witch") {
				gamepadcursor.width = this.width + 25 + 43;
				gamepadcursor.height = this.height + 42 + 19 - 50 * 6;
				if(!SpellbookPublic.canthrowdice) {
					gamepadcursor.y += 170;
				}
			} else if ((skillcard == "robot_calculate" || skillcard == "robot_request") && Game.player.roll_jackpot != 2) {
				gamepadcursor.x += 6;
				gamepadcursor.y += 5;
				gamepadcursor.width = 834 + 25 + 43 - 8;
				gamepadcursor.height = 1160 + 42 + 19 - 8;
			} else {
				gamepadcursor.width = this.width + 25 + 43;
				gamepadcursor.height = this.height + 42 + 19;
				
				if (this.upgraded) {
					gamepadcursor.y += 12;
					gamepadcursor.height -= 12;
				}
			}
			gamepadcursor.draw();
		}
		
		if (interactive){
			var col = equipmentcol < 0 ? Pal.GRAY : equipmentcol;
			foregroundcol = ExtendedGui.buttonpalette[col][0];
			backgroundcol = ExtendedGui.buttonpalette[col][1];
			bordercol = ExtendedGui.buttonpalette[col][2];
			highlightdicecol = ExtendedGui.buttonpalette[col][3];
			highlighttextcol = ExtendedGui.buttonpalette[col][6];
		}else{
			foregroundcol = ExtendedGui.buttonpalette[Pal.GRAY][0];
			backgroundcol = ExtendedGui.buttonpalette[Pal.GRAY][1];
			bordercol = ExtendedGui.buttonpalette[Pal.GRAY][2];
			highlightdicecol = ExtendedGui.buttonpalette[Pal.GRAY][3];
			highlighttextcol = ExtendedGui.buttonpalette[Pal.GRAY][6];
		}
		
		var silenced:Bool = false;
		if (Game.player != null){
			silenced = Game.player.hasstatus("silence");
		}
		currentheight = height;
		
		//Hide old states here (slightly redundant, but makes errors less likely)
		if (flashtime <= 0)	equipmentpanel.hideflash();
		if (shockedsetting <= 0) equipmentpanel.hideshock();			
		if (availablethisturn) equipmentpanel.hideunavailable();
		if (interactive) equipmentpanel.hidenoninteractive();
		if (!blackedout) equipmentpanel.hideblackout();
		
		var completerender:Bool = true;
		
		if (shockedsetting > 0){
			if(skillcard != ""){
				if (stolencard){
					if(equippedby.stolencard != null){
						width = equippedby.stolencard.width;
						height = equippedby.stolencard.height;
						positionshockslots(false);
					}
				}
			}
			
			if (shockedsetting > 0 && unshockingtimer > 0){
				var effect:Float;
				effect = Math.sin(2 * Math.PI * (unshockingtimer)) * 60 * 6;
				equipmentpanel.drawshockwitheffect(this, tx, ty, tx - effect, ty - effect, width + (effect * 2), currentheight + (effect * 2), Col.WHITE, 0.5 * alpha);
			}else{
				equipmentpanel.drawshock(this, tx, ty, alpha);
			}
			
			if (flashtime > 0){
				equipmentpanel.drawflash(this, tx, ty);
			}
			completerender = false;
		}else if (!availablethisturn){
			if(interactive){
				equipmentpanel.drawunavailable(this, tx, ty, alpha);
			}else{
				equipmentpanel.drawunavailable(this, tx, ty, alpha);
			}
			if (flashtime > 0){
				equipmentpanel.drawflash(this, tx, ty);
			}
			
			completerender = false;
		}else	if (!skillcard_special){
			if(interactive){
				if (locked > 0 && !unlockedthisturn){
					equipmentpanel.drawlockedpanel(this, tx, ty, alpha);
					if (locked > 0 && !unlockedthisturn){
						equipmentpanel.drawlockedslot(this, tx, ty, unlocked, locked, alpha);
					}		
				}else{
					equipmentpanel.draw(this, tx, ty, alpha);
				}
			}else{
				//Most for showing grayed out spells when playing Witch
				if(weakened){
					equipmentpanel.show_noninteractive(this, tx, ty, alpha);
				}else if (upgraded){
					equipmentpanel.show_noninteractive(this, tx, ty, alpha);
				}else if (locked > 0 && !unlockedthisturn){
					equipmentpanel.show_noninteractive(this, tx, ty, alpha);
				}else{
					equipmentpanel.show_noninteractive(this, tx, ty, alpha);
				}
			}
			
			currentheight = height - 30;
		}else{
			equipmentpanel.hideshock();
			
			if (stolencard){
				if(equippedby.stolencard != null){
					width = equippedby.stolencard.width;
					height = equippedby.stolencard.height;
					
					if(equippedby.stolencard != null){
						if (equippedby.stolencard.ready){
							//Potentially insert "to steal" slot here?
							//Game.fillbubble(x, y, width, height, Col.BLACK, 0.25);
							//Game.drawbubble(x, y, width, height, Col.BLACK);
						}
						
						if (skillcard == "warriorreunion"){
							//Hardcoding the position of a size 2 card in this position //2940
							//Reunion.warriorcard_drawemptyslot(tx, 462, alpha * 0.5);
						}
						
						equippedby.stolencard.x = tx;
						equippedby.stolencard.draw();
						
						if (skillcard == "thiefreunion"){
							if (equippedby.stolencard.y >= 0){
								Reunion.thiefcard_showbutton(equippedby.stolencard, tx, ty - y, alpha);
							}
						}else if (skillcard == "warriorreunion"){
							Reunion.warriorcard_showbutton(equippedby.stolencard, tx, Reunion.warriorcard_yposition, alpha);
						}else if (skillcard == "witchreunion"){
							Reunion.witchcard_showstunlock(equippedby.stolencard, tx, Reunion.witchcard_yposition, alpha);
						}
					}
				}
				completerender = false;
			}else{
				if (skillcard == "inventor"){
					Game.inventorskillcard(this, (flashtime > 0), silenced);
				}else if (skillcard == "skillskillcard"){
					Game.skillskillcard(this, (flashtime > 0), silenced);
				}else if (skillcard == "witch"){
					if(SpellbookPublic.canthrowdice){
						Game.witchskillcard(this, tx, ty, flashtime > 0);
					}else{
						Game.witchskillcard(this, tx, ty + 170, flashtime > 0);
					}
				}else if (skillcard == "switchfighter"){
					Monstermode.drawskillcard(this, tx, ty, flashtime > 0);
				}else {
					equipmentpanel.draw(this, tx, ty, alpha);
				}
			}
		}
		
		if (completerender) {
			//Rust counter!
			var drawtinydice:Bool = (totalusesremaining > 0);
			
			if (skillcard != "inventor" && skillcard != "skillskillcard"){  //Even though the Inventor Skillcard is a passive card, show durability on it
				if (slots != null){
					if (slots.length == 0) drawtinydice = false;
				}
			}
			
			if (drawtinydice){
				if (rustcounter.length == 0){
					rustcounter.push(new TinyDiceGraphic());
				}
				if (totalusesremaining == 1){
					rustcounter[0].draw(tx + width - 110, ty - 18, totalusesremaining - 1, 0.9 + (0.1 * Math.sin(flash.Lib.getTimer() / 200)));
					if (rustcounter.length > 1) rustcounter[1].remove();
				}else if (totalusesremaining > 12){
					rustcounter[0].draw(tx + width - 110, ty - 18, 6, 0.7);
					if (rustcounter.length > 1) rustcounter[1].remove();
				}else if (totalusesremaining > 6){
					if (rustcounter.length == 1){
						rustcounter.push(new TinyDiceGraphic());
					}
					rustcounter[0].draw(tx + width - 60, ty - 18, 5, 0.7);
					rustcounter[1].draw(tx + width - 200, ty - 18, totalusesremaining - 7, 0.7);
				}else{
					rustcounter[0].draw(tx + width - 110, ty - 18, totalusesremaining - 1, 0.7);
					if (rustcounter.length > 1) rustcounter[1].remove();
				}
			}
			
			//Monstermode healthbar
			if (showhealthbar){
				if (Game.hideskills){
					healthbar.draw(tx + (width / 2) - (healthbar.width / 2) + 6, ty + currentheight - 200 - (7 * 6), monstercard.hp, monstercard.maxhp, 0, false);
				}else{
					healthbar.draw(tx + (width / 2) - (healthbar.width / 2) + 6, ty + currentheight - 200, monstercard.hp, monstercard.maxhp, 0, false);
				}
			}
			
			if (flashtime > 0){
				equipmentpanel.drawflash(this, tx, ty);
			}else{
				equipmentpanel.hideflash();
			}
			
			equipmentpanel.hideblackout();
		}
		
		// Gamepad highlight, part two
		if (showgamepadhighlight()) {
			var gamepadcursor2:HaxegonSprite = null;
			if (this.size == 2) {
				if (gamepadcursor2_large == null) {
					gamepadcursor2_large = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_tall_toplayer");
					gamepadcursor2_large.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171 + (1216 - 655));
				}
				gamepadcursor2 = gamepadcursor2_large;
			} else if (this.y + 0.5*this.height < Screen.heightmid) {
				if (gamepadcursor2_small1 == null) {
					gamepadcursor2_small1 = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_small_toplayer");
					gamepadcursor2_small1.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171);
				}
				gamepadcursor2 = gamepadcursor2_small1;
			} else {
				if (gamepadcursor2_small2 == null) {
					gamepadcursor2_small2 = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_small_toplayer");
					gamepadcursor2_small2.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171);
				}
				gamepadcursor2 = gamepadcursor2_small2;
			}
			
			gamepadcursor2.x = tx - 25;
			gamepadcursor2.y = ty - 42;
			
			if (skillcard == "witch") {
				gamepadcursor2.width = this.width + 25 + 43;
				gamepadcursor2.height = this.height + 42 + 19 - 50 * 6;
				if(!SpellbookPublic.canthrowdice) {
					gamepadcursor2.y += 170;
				}
			} else if ((skillcard == "robot_calculate" || skillcard == "robot_request") && Game.player.roll_jackpot != 2) {
				gamepadcursor2.x += 6;
				gamepadcursor2.y += 5;
				gamepadcursor2.width = 834 + 25 + 43 - 8;
				gamepadcursor2.height = 1160 + 42 + 19 - 8;
			} else {
				gamepadcursor2.width = this.width + 25 + 43;
				gamepadcursor2.height = this.height + 42 + 19;
			}
			gamepadcursor2.alpha = 0.5 + 0.5 * Math.sin(6.283 * Lib.getTimer() / 2000);
			gamepadcursor2.draw();
		}
		
		// Gamepad selection
		if (showgamepadhighlight() && interactive && Combat.gamepad_dicemode && Combat.gamepad_hidedicetrailtime <= 0) {
			// If we have a diceslot, show gamepad_selecteddice over it...
			if (Combat.gamepad_hoverdice != null && Combat.gamepad_selecteddice != null && !Combat.gamepad_pendingrearrange && !Combat.gamepad_dicerequesting && !combination) {
				var hoverslot:Point = getgamepadslot(Combat.gamepad_selecteddice);

				if (hoverslot != null) {
					Combat.gamepad_hoverdice.copyfrom(Combat.gamepad_selecteddice);
					
					if (Combat.gamepad_selecteddice.burn) {
						if (!Combat.gamepad_hoverdice.burn) {
							Combat.gamepad_hoverdice.burnnow();
						}
					} else {
						if (Combat.gamepad_hoverdice.burn) {
							Combat.gamepad_hoverdice.removeburneffect();
						}
					}
					
					Combat.gamepad_hoverdice.x = tx + hoverslot.x + 20;
					Combat.gamepad_hoverdice.y = ty + hoverslot.y + 20;
					
					if (skillcard != "witch" || shockedsetting != 0) {
						Combat.gamepad_hoverdice.dicealpha = 0.25;
						Combat.gamepad_hoverdice.draw();
						Combat.gamepad_hoverdice.updateoverlay();
						
						// Will this dice fit in this slot?
						if (!Combat.gamepad_selecteddice.blind && !Combat.isdicevalidonequipment(Combat.gamepad_selecteddice.basevalue, Combat.gamepad_selectedequipment)) {
							// No, it won't. Show an error cursor.
							Combat.gamepad_hoverdice.graphic.unacceptableimageonslot.x = Combat.gamepad_hoverdice.x + Combat.gamepad_hoverdice.shakex - 40;
							Combat.gamepad_hoverdice.graphic.unacceptableimageonslot.y = Combat.gamepad_hoverdice.y + Combat.gamepad_hoverdice.shakey - 40;
							Combat.gamepad_hoverdice.graphic.unacceptableimageonslot.draw();
						}
					}
				}
			}
			
			// If we have a button, highlight a button...
		}

		if (gadgettooltip_enabled && !Combat.combatmode) {
			if(gadgettooltip_id == null) {
				preparegadgettooltip();
			}
			if(gadgettooltip_id != null && TooltipManager.hastooltip(gadgettooltip_id)) {
				var tooltip = TooltipManager.gettooltip(gadgettooltip_id);
				var tooltipx = tx + (width/2 - tooltip.width()/2);
				//var tooltipy = ty + (height/2 - tooltip.height()/2);
				var tooltipy = ty - tooltip.height() - (1 * 6);
				//var tooltipy = ty + height + (1 * 6);
				TooltipManager.setpositiontype(gadgettooltip_id, 1, tooltipx, tooltipy, 0, 0);
				TooltipManager.forcetooltipdraw(gadgettooltip_id, true);
			}
		} else {
			TooltipManager.forcetooltipdraw(gadgettooltip_id, false);
		}
		
		if (Rules.manualequipmentfiring){
			if(Combat.turn == "player"){
				if (hasmanualbutton()){
					Gui.moveto(tx + width - ExtendedGui.halfbuttonwidth + (4 * 6), ty - (2 * 6));
					if (Combat.canmanualfire(this)){
						Reunion.getmanualbutton(this, false).remove();
						var b:Button = Reunion.getmanualbutton(this, true);
						b.usespamdelay = true;
						b.spamdelay = 9999;
						for (d in assigneddice){
							if(d != null){
								if (Game.intween(d)){
									b.spamdelay = 0; //Prevent assigning the dice from also firing the equipment
								}
							}
						}
						
						var canfirewithgamepad:Bool = (Combat.gamepad_selectedequipment == this) && !LimitBreakPrompt.showing;
						if (b.showmediumanddraw("Play[][]", 0, "", false, canfirewithgamepad?lime.ui.GamepadButton.A:-1)){
							Combat.manualfire(this);
						}
					}else{
						Reunion.getmanualbutton(this, true).remove();
						Reunion.getmanualbutton(this, false).unavailableshowmediumanddraw("Play[][]");
					}
				}
			}
		}
		
		//Show debug info: assigned die to equipment
		/*
		var t:String = "[";
		for (i in 0 ... assigneddice.length){
			if (assigneddice[i] == null){
				t += "null,";
			}else{
				t += assigneddice[i].value + ",";
			}
		}
		t += "]";
		FutureDraw.print(x + width, y, t);
		*/
	}
	
	public function hasmanualbutton():Bool{
		//If the card has no owner, then it's in a context where we shouldn't show the manual button
		if (equippedby == null) return false;
		
		//If this is the skill card, then no manual button
		if (skillcard != "") return false;
		if (equippedby.stolencard == this) return false;
		
		//Combinations and countdowns never have manual buttons
		if(slots.length > 0){
			if (slots[0] == DiceSlotType.COMBINATION) return false;
			if (slots[0] == DiceSlotType.COUNTDOWN) return false;
		}
		
		//If the card is shocked, no manual button
		if (shockedsetting > 0){
			return false;
		}
		
		if (!availablethisturn){
			return false;
		}
		
		//Passive cards never have manual buttons
		if (slots.length == 0){
			return false;
		}
		
		//If we're previewing enemy equipment, no manual button
		if (Combat.previewingequipment) return false;
		
		//If we're not in combat, no manual button
		if (!Combat.combatmode) return false;
		
		return true;
	}
	
	public function shakeslot(s:Int, xoff:Float, yoff:Float){
		if (xoff != 0){
			slotshake[s].x = xoff;
			Actuate.tween(slotshake[s], 0.08 / BuildConfig.speed, { x: 0 });
			if (assigneddice[s] != null){
				var oldx:Float = assigneddice[s].x;
				assigneddice[s].x += xoff;
				Actuate.tween(assigneddice[s], 0.08 / BuildConfig.speed, { x: oldx });
			}
		}
		if (yoff != 0){
			slotshake[s].y = yoff;
			Actuate.tween(slotshake[s], 0.08 / BuildConfig.speed, { y: 0 });
			if (assigneddice[s] != null){
				var oldy:Float = assigneddice[s].y;
				assigneddice[s].y += yoff;
				Actuate.tween(assigneddice[s], 0.08 / BuildConfig.speed, { y: oldy });
			}
		}
	}
	
	public function updatereuseabledescription(){
		if(allowupdatereuseabledescription){
			if (reuseable != 0){
				if (usesleft == -1){
					overwritefinalline = "[gray](Reuseable)";
				}else	if (usesleft <= 1){
					overwritefinalline = "[gray](One use this turn)";
				}else{
					overwritefinalline = "[gray](" + usesleft + " uses this turn)";
				}
			}
		}
	}
	
	public function clearalternatelock(){
		if (equippedby != null){
			if (equippedby.hadstatus(Status.ALTERNATE_LOCK)){
				for (d in assigneddice){
					if (d != null){
						d.priority = false;
					}
				}
			}
		}
	}
	
	public function hideassigneddice(){
		for (d in assigneddice){
			if (d != null){
				d.dicealpha = 0;
			}
		}
	}
	
	public function showassigneddice(){
		for (d in assigneddice){
			if (d != null){
				if (!d.consumed){
					d.dicealpha = 1;
				}
			}
		}
	}
	
	public function doequipmentaction(actor:Fighter, target:Fighter, dir:Int, actualdice:Array<Dice>, equipdelay:Float, ignorecurse:Bool, allowfury:Bool, isrepeated:Bool = false){
		var dicesum:Int = getpower();
		
		if (scriptbeforeexecute != ""){
			if(equippedby == null) equippedby = Game.fixequippedbyfield(this);
			Script.rungamescript(scriptbeforeexecute, "equipment_beforeexecute", equippedby, this, null, dicesum, actualdice);
			
			if (preventdefault){
				preventdefault = false;
				
				for (i in 0 ... assigneddice.length){
					if (assigneddice[i] != null){
						assigneddice[i].consumedice();
					}
				}
				
				if (countdown > 0) remainingcountdown = countdown;
				Combat.resetstolencardcountdown(this);
				Combat.resetjesterdeckcountdown(this);
				Combat.resetinventorcountdown(this);
				ready = false;
				
				if (actor.layout == EquipmentLayout.DECK) {
					DeckPublic.advance(0.8);
				}
				
				return;
			}
		}
		
		if (actor != null){
			actor.equipmenthistory.push(this);
		}
		
		if (!isrepeated){
			//For measuring damage output from Fury!
			damagethisscript = 0;
		}
		
		if (LadyLuckCommands.active){
			LadyLuckCommands.check("useequipment", [this], actualdice);
		}

		var actorhp = actor.hp;
		var targethp = target.hp;
		
		if (Rules.inventor_equipmentrust > 0){
			//Rust only applies to player equipment
			if (actor != Game.player){
				totalusesremaining = 0;
			}
		}
		
		//Kludge for fixing directions on conditional equipment
		if (castdirection == 4){
			if (dicesum != 1) dir = dir * -1;
		}else if (castdirection == 3){
			if (dicesum == 1) dir = dir * -1;
		}else if (castdirection == 2){
			if (dicesum % 2 == 1) dir = dir * -1;
		}else{
			dir = dir * castdirection;
		}
		
		var cursedequipment:Bool = false;
		var cursedchangetarget:Bool = false;
		var cursereuse:Bool = false;
		if (actor.hasstatus(Status.CURSE) && !ignorecurse && skillcard == ""){
			var cursetriggered:Bool = Random.chance(Rules.curseodds);
			if (hastag("curseavoid")) cursetriggered = false;
			if (hastag("curseattract")) cursetriggered = true;
			
			if (cursetriggered){
				cursedequipment = true;
				var cursestat:StatusEffect = actor.getstatus(Status.CURSE);
				cursestat.value--;
				cursestat.displayvalue = cursestat.value;
				if (cursestat.value <= 0){
					actor.removestatus(Status.CURSE);
				}
				
				for (s in actor.status)	s.runscript("oncursetrigger", dicesum, this);
			}else{
				if (hastag("reuseableifcursed")){
					cursereuse = true;
				}
			}
		}else if (actor.hasstatus(Status.ALTERNATE_CURSE) && !ignorecurse && skillcard == ""){
			var altcursetriggered:Bool = Random.chance(Rules.curseodds);
			if (hastag("curseavoid")) altcursetriggered = false;
			if (hastag("curseattract")) altcursetriggered = true;
			
			if (altcursetriggered){
				cursedequipment = true;
				cursedchangetarget = true;
				
				var alternatecursestat:StatusEffect = actor.getstatus(Status.ALTERNATE_CURSE);
				alternatecursestat.value--;
				alternatecursestat.displayvalue = alternatecursestat.value;
				if (alternatecursestat.value <= 0){
					actor.removestatus(Status.ALTERNATE_CURSE);
				}
				
				dir = -dir;
				
				AudioControl.play("_curse");
				animate("cursereverse");
				
				for (s in actor.status)	s.runscript("oncursetrigger", dicesum, this);
			}else{
				if (hastag("reuseableifcursed")){
					cursereuse = true;
				}
			}
		}
		
		if (actor.hasstatus("reversenexttarget")){
			var canreversenexttarget:Bool = true;
			if (hastag("curseavoid")) canreversenexttarget = false;
			if(canreversenexttarget){
				cursedequipment = true;
				cursedchangetarget = true;
				
				var reversetargetstat:StatusEffect = actor.getstatus("reversenexttarget");
				reversetargetstat.value--;
				reversetargetstat.displayvalue = reversetargetstat.value;
				if (reversetargetstat.value <= 0){
					actor.removestatus("reversenexttarget");
				}
				
				dir = -dir;
			}
		}
		
		var desty:Float = 0;
		if (dir == 1){
			desty = -(height * 1.5);
		}else{
			desty = Screen.height + (height * 0.5);
		}
		
		if (!cursedchangetarget && cursedequipment){
			AudioControl.play("_curse");
			animate(Status.CURSE);
			for (i in 0 ... assigneddice.length){
				if (assigneddice[i] != null){
					assigneddice[i].consumedice();
				}
			}

			// reset combinations
			if(combination) {
				Combination.reset(this);
			}
			
			if (countdown > 0) remainingcountdown = countdown;
			Combat.resetstolencardcountdown(this);
			Combat.resetjesterdeckcountdown(this);
			Combat.resetinventorcountdown(this);
			ready = false;
			
			if (actor.layout == EquipmentLayout.DECK) {
				DeckPublic.advance(0.8);
			}
		}else{
			function equipmenttween(_e:Equipment, sourceequipment:Equipment, _d:Int, _actualdice:Array<Dice>, allowfury:Bool){
				var destorydiceafteruse:Bool = true;
				
				Tutorial.reportevent("equipmentused");
				actor.equipmentused++;
				
				_e.show = false;
				if (_e.combination) Combination.reset(_e);
				_e.equipmentpanel.dispose();
				_e.sourceequipment = sourceequipment;
				
				var hasfury:Bool = false;
				if (allowfury){
					if (actor.hasstatus(Status.FURY) 
					 || actor.hasstatus(Status.ALTERNATE + Status.FURY)
					 || actor.hasstatus("spookyfury")
					 || actor.hasstatus("doublespookyfury")){
						var activatefury:Bool = true;
						if (actor.hasstatus("spookyfury")){
							if (Random.chance(50)){
								activatefury = false; //50% chance to fail
							}else{
								if (skillcard == ""){
									if (_e.scriptiffury == ""){
										AudioControl.play("_fury");
										actor.symbolparticle(Status.FURY); //Show the status effect!
									}
								}
							}
						}
						if(activatefury){
							if (skillcard != ""){
							}else{
								if (_e.scriptiffury != "" && !_e.alreadyfuryed){
									Script.rungamescript(_e.scriptiffury, "fury", _e.equippedby, _e, null, _d, _actualdice);
								}
								_e.show = true;
								destorydiceafteruse = false;
								
								if (!_e.maintainfury){
									if (actor.hasstatus(Status.ALTERNATE_FURY)){
										actor.decrementstatus(Status.ALTERNATE + Status.FURY, true);
										sourceequipment.availablenextturn = false;
										sourceequipment.unavailabletext = _e.displayname;
										sourceequipment.unavailablemodifier = _e.namemodifier;
										sourceequipment.unavailabledetails = ["Unavailable (Fury?)"];
									}else if (actor.hasstatus("spookyfury")){
										//Kludge to make sure that when Spooky Fury triggers, it activates twice
										var spookyfurykludge:StatusEffect = actor.getstatus("spookyfury");
										if (spookyfurykludge.value >= 2){
											//doublespookyfury is a secret, background status effect that makes
											//sure this works correctly
											actor.addstatus("doublespookyfury", spookyfurykludge.value - 1);
											spookyfurykludge.value = 0;
											actor.removestatus("spookyfury");
										}else{
											actor.decrementstatus("spookyfury", true);
										}
									}else if (actor.hasstatus("doublespookyfury")){
										actor.decrementstatus("doublespookyfury", true);
									}else{
										actor.decrementstatus(Status.FURY, true);
									}
								}else{
									if (actor.hasstatus(Status.ALTERNATE_FURY)){
										sourceequipment.availablenextturn = false;
										sourceequipment.unavailabletext = _e.displayname;
										sourceequipment.unavailablemodifier = _e.namemodifier;
										sourceequipment.unavailabledetails = ["Unavailable (Fury?)"];
									}
								}
								
								if (_e.preventdefault){
									_e.preventdefault = false;
								}else{
									if (_e.alreadyfuryed){
										_e.alreadyfuryed = false;
										_e.maintainfury = false;
									}else{
										if (_e.maintainfury) _e.alreadyfuryed = true;
										AudioControl.play("equipmentisfury");
										Combat.repeatlastaction(actor, target, _e);
										hasfury = true;
									}
								}
							}
						}
					}
				}
				
				_e.ready = false;
				
				var applydodge:Bool = false;
				var applyalternatedodge:Bool = false;
				if (target.hasstatus(Status.DODGE) && _e.castdirection == 1){
					applydodge = true;
				}else if (target.hasstatus(Status.DODGE) && _e.castdirection == 2 && (_d % 2 == 0)){
					//Er, this is a mess. Fix eventually!
					//Special case for spiked shield, which only casts backwards 50% of the time
					applydodge = true;
				}else if (target.hasstatus(Status.ALTERNATE_DODGE) && _e.castdirection == 1){
					if (Random.chance(Rules.alternatedodgeodds)){
						applyalternatedodge = true;
					}
				}else if (target.hasstatus(Status.ALTERNATE_DODGE) && _e.castdirection == 2 && (_d % 2 == 0)){
					//Er, this is a mess. Fix eventually!
					//Special case for spiked shield, which only casts backwards 50% of the time
					if (Random.chance(Rules.alternatedodgeodds)){
						applyalternatedodge = true;
					}
				}
				
				if (applydodge){
					var dodgestat:StatusEffect = target.getstatus(Status.DODGE);
					dodgestat.value--;
					dodgestat.displayvalue = dodgestat.value;
					if (dodgestat.value <= 0){
						target.removestatus(Status.DODGE);
					}
					AudioControl.play("use_dodge_status_to_avoid");
					if (_e.scriptondodge != ""){
						Script.rungamescript(_e.scriptondodge, "dodge", _e.equippedby, _e, null, _d, _actualdice);
					}
					
					for (s in target.status) s.runscript("ondodge", _d, _e);
					for (s in actor.status) s.runscript("onenemydodge", _d, _e);
				}else if (applyalternatedodge){
					var altdodgestat:StatusEffect = target.getstatus(Status.ALTERNATE_DODGE);
					altdodgestat.value--;
					altdodgestat.displayvalue = altdodgestat.value;
					if (altdodgestat.value <= 0){
						target.removestatus(Status.ALTERNATE_DODGE);
					}
					AudioControl.play("use_dodge_status_to_avoid");
					if (_e.scriptondodge != ""){
						Script.rungamescript(_e.scriptondodge, "dodge", _e.equippedby, _e, null, _d, _actualdice);
					}
					
					for (s in target.status) s.runscript("ondodge", _d, _e);
					for (s in actor.status) s.runscript("onenemydodge", _d, _e);
				}else{
					if (scriptrunner == null) scriptrunner = Script.load(script);
					scriptrunner.hasfury = hasfury;
					//Figure out if we're using an alternate burning dice
					var usingalternateburningdice:Bool = false;
					if (_actualdice != null){
						for (d in _actualdice){
							if(d != null){
								if (d.alternateburn) usingalternateburningdice = true;
							}
						}
					}
					if (!usingalternateburningdice){
						if (countdown > 0){
							for (i in 0 ... dicehistory.length){
								if (dicehistory[i].alternateburn){
									usingalternateburningdice = true;
								}
							}
						}
					}
					
					if (usingalternateburningdice){
						availablenextturn = false;
						availablethisturn = false;						
						unavailabletext = sourceequipment.displayname;
						unavailablemodifier = sourceequipment.namemodifier;
						unavailabledetails = ["Unavailable (Burn?)"];
						if (sourceequipment != _e){
							sourceequipment.animate("flash");
							sourceequipment.availablethisturn = false;
							sourceequipment.unavailabletext = sourceequipment.displayname;
							sourceequipment.unavailablemodifier = sourceequipment.namemodifier;
							sourceequipment.unavailabledetails = ["Unavailable (Burn?)"];
						}
					}
					
					if (cursedchangetarget && cursedequipment){
						Script.actionexecute(scriptrunner, target, actor, _d, _actualdice, _e, this);
						Script.callechoscripts_equipment(actor, _e);
					}else{
						Script.actionexecute(scriptrunner, actor, target, _d, _actualdice, _e, this);
						Script.callechoscripts_equipment(actor, _e);
					}
					
					cleardicehistory();
					ProgressTracking.equipmentusechecks(this);
					
					//Run appended rule scripts
					if (Rules.extrascript_playerequipmentuse.length > 0 || Rules.extrascript_enemyequipmentuse.length > 0){
						var scripttarget:String = "equipment_onexecute";
						if (cursedchangetarget && cursedequipment){
							scripttarget = "reversetargetequipment_onexecute";
						}
						
						if (equippedby == Game.monster){
							if (Rules.extrascript_enemyequipmentuse.length > 0){
								for(i in 0 ... Rules.extrascript_enemyequipmentuse.length){
									Script.rungamescript(Rules.extrascript_enemyequipmentuse[i], scripttarget, equippedby, this, null, _d, _actualdice);	
								}
							}
						}else{
							if (Rules.extrascript_playerequipmentuse.length > 0){
								for(i in 0 ... Rules.extrascript_playerequipmentuse.length){
									Script.rungamescript(Rules.extrascript_playerequipmentuse[i], scripttarget, Game.player, this, null, _d, _actualdice);
								}
							}
						}
					}
					
					var actorpowertag = Game.gettag(actorhp - actor.hp);
					var targetpowertag = Game.gettag(targethp - target.hp);
					
					if(actorpowertag != null && ((actorhp - actor.hp) > 0)) {
						actor.symbolparticle('attack_${actorpowertag}');
					}
					
					if(targetpowertag != null && ((targethp - target.hp) > 0)) {
						target.symbolparticle('attack_${targetpowertag}');
					}
					
					var isplayer = actor == Game.player;
					
					if (sfxoverride != "none"){
						if (isplayer) {
						//trace("playing sound for " + _e.name + " yep");
							if (sfxoverride.length > 0){
								AudioControl.play(sfxoverride, targetpowertag);
							}else	if(playersound.length > 0) {
								AudioControl.play(playersound, targetpowertag);
								//trace(playersound);
							}
						} else {
							if (sfxoverride.length > 0){
								AudioControl.play(sfxoverride, targetpowertag);
							}else	if (enemysound.length > 0) {
								AudioControl.play(enemysound, targetpowertag);
							} else if (playersound.length > 0) {
								AudioControl.play(playersound, targetpowertag);
							}
						}
						if (upgraded){
							AudioControl.play("equipmentisupgraded");
						}else if (weakened){
							AudioControl.play("equipmentisdowngraded");
						}
					}
					
					//Play the character's voice
					/*
					if (actor.isplayer){
						if (_e.castdirection == 1){
							AudioControl.play("chat_" + actor.name.toLowerCase() + "_voice", "action");
						}
					}else{
						if (actor.voice != ""){
							if (_e.castdirection == 1){
								AudioControl.playvoice(actor.voice, "action");
							}
						}
					}*/
					
					//Play the target's voice
					if (target.isplayer){
						if (_e.castdirection == 1){
							Game.delaycall(function(){
								if (Rules.monstermode){
									if (Monstermode.usingstandardplayer){
										AudioControl.play("chat_" + target.name.toLowerCase() + "_voice", "action");
									}else{
										AudioControl.playvoice(target.voice, "action");
									}
								}else{
									AudioControl.play("chat_" + target.name.toLowerCase() + "_voice", "action");
								}
							}, 0.1);
						}
					}else{
						if (target.voice != ""){
							if (_e.castdirection == 1){
								Game.delaycall(function(){
									AudioControl.playvoice(target.voice, "action");
								}, 0.1);
							}
						}
					}

					for(dice in _actualdice) {
						if(dice != null) dice.showoverlayimage = false;
					}
				}
				
				actor.equipmentslotsleft += size;
				_e.usedthisbattle = true;
				
				//If we're in Thief Reunion mode, and this is the stolen card, and it's
				//once per battle, then we mark it as used so we can't use it again.
				if (_e.onceperbattle){
					if (actor.hasstolencard){
						if (actor.stolencard == _e){
							if(Reunion.thiefcard_selected != ""){
								Reunion.thiefcard_onceperbattle = 2;
							}
						}
					}
				}
				
				//If we're in Warrior Reunion mode, and this is the stolen card, just mark it as used
				if (actor.hasstolencard){
					if (actor.stolencard == _e){
						Reunion.warriorcard_positionbutton_center();
						Reunion.warriorcard_used = true;
					}
				}
				
				//For timesused: if it's reuseable equipment, then this variable has already been changed
				if (sourceequipment == _e){
					_e.timesused++;
				}
				
				if (destorydiceafteruse){
					_e.hideassigneddice();
					_e.clearalternatelock();
				}
				
				if (_e.countdown > 0) _e.remainingcountdown = _e.countdown;
				Combat.resetstolencardcountdown(_e);
				Combat.resetjesterdeckcountdown(_e);
				Combat.resetinventorcountdown(_e);
				
				//If we're playing as Jester, advance the Deck now
				if (actor.layout == EquipmentLayout.DECK){
					if(!hasfury){
						DeckPublic.advance(0.2 / BuildConfig.speed);
					}else{
						DeckPublic.advance(0.7 / BuildConfig.speed);
					}
				}
			}
			
			//Check that you have this BEFORE using any equipment that might give you this
			var learntrecycle:Bool = false;
			
			if(!hastag("cannotreuse")){
				learntrecycle = actor.hasstatus(Status.RECYCLE);
					
				if (actor.hasstatus(Status.REEQUIPNEXT)){
					if (equippedby == null) equippedby = actor;
					var reequipnext:StatusEffect = actor.getstatus(Status.REEQUIPNEXT);
					reequipnext.value--;
					reequipnext.displayvalue = reequipnext.value;
					if (reequipnext.value <= 0){
						actor.removestatus(Status.REEQUIPNEXT);
					}
					
					learntrecycle = true;
				}
			}
			
			if (cursereuse){
				learntrecycle = true;
			}
			
			if(Rules.inventor_equipmentrust > 0){
				if (totalusesremaining > 0){
					if(!onceperbattle && !removefromthisbattle){
						learntrecycle = true;
					}
				}
			}
			
			if (reuseable != 0 || learntrecycle){
				//We create a temporary copy of this equipment, and reassign our dice to it.
				//The current equipment stays where it is.
				var reuseablecopy:Equipment = copy();
				reuseablecopy.x = x;
				reuseablecopy.y = y;
				reuseablecopy.reuseable = 0;
				reuseablecopy.ready = false;
				reuseablecopy.weakened = weakened;
				reuseablecopy.totalusesremaining = 0;
				reuseablecopy.equipmentcol = equipmentcol;
				//Copy vars to reuseable equipment
				reuseablecopy.gamevar = new Map<String, Dynamic>();
				for (key in gamevar.keys()) reuseablecopy.gamevar.set(key, gamevar.get(key));
				//Copy dicehistory too
				if (dicehistory != null){
					if(dicehistory.length > 0){
						reuseablecopy.cleardicehistory();
						for (d in dicehistory){
							reuseablecopy.dicehistory.push(d);
						}
					}
				}
				
				//If locked equipment is reused, we need to "unlock" the temporary copy
				if(reuseablecopy.locked > 0){
					reuseablecopy.locked = 0;
					reuseablecopy.unlockedthisturn = true;
					
					LockedRobotEquipment.changelockedslotstorealslots(reuseablecopy);
				}
				
				//Combinations: We reset the variables on the original equipment now
				if(combination){
					Combination.reset(this);
				}
				
				if(!learntrecycle){
					if (reuseable > 0 && usesleft > 0){
						usesleft--;
						updatereuseabledescription();
					}
				}
				
				//Reset countdown for rare reusable countdowns
				if (countdown > 0) remainingcountdown = countdown;
				Combat.resetstolencardcountdown(this);
				Combat.resetjesterdeckcountdown(this);
				Combat.resetinventorcountdown(this);
				
				ready = false;
				
				if (usesleft == 0 && !learntrecycle){
					playcharactervoice(actor, this);
					Actuate.tween(this, 0.5 / (BuildConfig.speed * Settings.animationspeed), { y: desty })
						.ease(Back.easeIn)
						.delay(equipdelay / BuildConfig.speed)
						.onComplete(equipmenttween, [this, this, dicesum, actualdice, true]);
				}else{
				  timesused++;
					reuseableanimation = 0.5;
					
					for (i in 0 ... slots.length){
						var d:Dice = assigneddice[i];
						if (d != null){
							removedice(d);
							reuseablecopy.assigndice(d, i);
						}
					}
					
					actualdice = [];
					for (i in 0 ... reuseablecopy.assigneddice.length){
						actualdice.push(reuseablecopy.assigneddice[i]);
					}
					
					tempreuseableequipment.push(reuseablecopy);
						
					var activaterust:Bool = false;
					if (Rules.inventor_equipmentrust > 0 && totalusesremaining == 1){
						activaterust = true;
						if (reuseable > 0){
							if (usesleft != 1){
								activaterust = false;
							}
						}
					}
					
					if (activaterust){
						//Rust!
						animate("error");
						ready = false;
						active = false;
						
						//Mark the equipment as destroyed
						onceperbattle = true; usedthisbattle = true;
						totalusesremaining = -1;
						
						//Change the gadget!
						Game.updategadget(this);
					}else{
						if (Rules.inventor_equipmentrust > 0 && totalusesremaining != 0){
							if (reuseable > 0){
								usesleft--;
								if (usesleft != 0){
									updatereuseabledescription();
								}else{
									usesleft = reuseable;
									updatereuseabledescription();
									if (totalusesremaining > 0) totalusesremaining--;
								}
							}else{
								if (totalusesremaining > 0) totalusesremaining--;
							}
						}
						//Make the card available again
						ready = true;
						
						//For spare dice slots, we recreate the dice now if we need to
						actor.createsparedice(this);
					}

					// update the reuseablecopy data
					reuseablecopy.usedthisbattle = usedthisbattle;
					reuseablecopy.onceperbattle = onceperbattle;
					// we already incremented the times this equipment was used before which seems to break some equipment
					// that depends on this variable, let's decrement it here to avoid those issues
					reuseablecopy.timesused = timesused - 1;
					reuseablecopy.usesleft = usesleft;
					reuseablecopy.totalusesremaining = totalusesremaining;

					playcharactervoice(actor, this);
					Actuate.tween(reuseablecopy, 0.5 / (BuildConfig.speed * Settings.animationspeed), { y: desty })
						.ease(Back.easeIn)
						.delay(equipdelay / BuildConfig.speed)
						.onComplete(function(){
							
							equipmenttween(reuseablecopy, this, dicesum, actualdice, true);
							
							//If equipment changes any evars, we need to update that on the base equipment
							gamevar = new Map<String, Dynamic>();
							for (key in reuseablecopy.gamevar.keys()) gamevar.set(key, reuseablecopy.gamevar.get(key));
						});
				}
			}else{
				playcharactervoice(actor, this);
				Actuate.tween(this, 0.5 / (BuildConfig.speed * Settings.animationspeed), { y: desty })
					.ease(Back.easeIn)
					.delay(equipdelay / BuildConfig.speed)
					.onComplete(equipmenttween, [this, this, dicesum, actualdice, true]);
			}
		}
	}
	
	public function playcharactervoice(actor:Fighter, _e:Equipment){
		//Play the character's voice
		if (actor.isplayer && !actor.is_a_transformed_character){
			if (_e.castdirection == 1){
				if (Rules.monstermode){
					if (Monstermode.usingstandardplayer){
						Game.delaycall(function(){
							AudioControl.play("chat_" + actor.name.toLowerCase() + "_voice", "action");
						}, 0.3);
					}else{
						Game.delaycall(function(){
							AudioControl.playvoice(actor.voice, "action");
						}, 0.3);
					}
				}else{
					Game.delaycall(function(){
						AudioControl.play("chat_" + actor.name.toLowerCase() + "_voice", "action");
					}, 0.3);
				}
			}
		}else{
			if (actor.voice != ""){
				if (_e.castdirection == 1){
					Game.delaycall(function(){
						AudioControl.playvoice(actor.voice, "action");
					}, 0.3);
				}
			}
		}
	}
	
	public function getnumassigneddice():Int{
		var numassigneddice:Int = 0;
		for (i in 0 ... assigneddice.length){
			if (assigneddice[i] != null) numassigneddice++;
		}
		
		return numassigneddice;
	}
	
	public function getnumassignedshockeddice():Int{
		var numassigneddice:Int = 0;
		for (i in 0 ... shocked_assigneddice.length){
			if (shocked_assigneddice[i] != null) numassigneddice++;
		}
		
		return numassigneddice;
	}
	
	/* This function is used instead of getpower in Game.equipmentstring().
	 * It includes the value of targetting dice, and also takes blind into account */
	public function getpower_forequipmentstring(f:Fighter):Array<Int>{
		var dicesum:Int = 0;
		var freeslotpower:Int = 0;
		var emptyslots:Int = 0;
		var blinded:Int = 0;
		
		if (countdown > 0){
			dicesum = countdown;
		}else{
			for (i in 0 ... assigneddice.length){
				if (assigneddice[i] != null){
					dicesum += assigneddice[i].value;
					if (assigneddice[i].blind) blinded = 1;
				}else{
					emptyslots++;
				}
			}
		}
		
		//Also include dice that are targetting the equipment
		if(emptyslots > 0){
			if (f != null){
				for (d in f.dicepool){
					if (emptyslots > 0){
						if (!d.consumed && d.dicealpha > 0.2){ //Don't count dice that are used already
							if (d.istargetting(this)){ //This dice is targetting this equipment
								if (d.blind){
									dicesum += d.value;
									blinded = 1;
									emptyslots--;
								}else{
									for (i in 0 ... slots.length){
										if(assigneddice[i] == null){ //This exact slot is free
											if(Combat.dicematchesslot(d.value, slots[i])){ //And this dice fits in it
												if (assigneddice.indexOf(d) == -1){
													dicesum += d.value;
													if (d.blind) blinded = 1;
													emptyslots--;
													break;
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		for (i in 0 ... slots.length){
			if (slots[i] == DiceSlotType.FREE1) freeslotpower += 1;
			if (slots[i] == DiceSlotType.FREE2) freeslotpower += 2;
			if (slots[i] == DiceSlotType.FREE3) freeslotpower += 3;
			if (slots[i] == DiceSlotType.FREE4) freeslotpower += 4;
			if (slots[i] == DiceSlotType.FREE5) freeslotpower += 5;
			if (slots[i] == DiceSlotType.FREE6) freeslotpower += 6;
		}
		
		return [dicesum + freeslotpower, freeslotpower, blinded];
	}
	
	public function getpower(withfreeslots:Bool = true):Int{
		var dicesum:Int = 0;
		var emptyslots:Int = 0;
		
		if (countdown > 0){
			dicesum = countdown;
		}else{
			for (i in 0 ... assigneddice.length){
				if(assigneddice[i] != null){
					dicesum += assigneddice[i].value;
				}else{
					emptyslots++;
				}
			}
		}
		
		if(withfreeslots){
			for (i in 0 ... slots.length){
				if (slots[i] == DiceSlotType.FREE1) dicesum += 1;
				if (slots[i] == DiceSlotType.FREE2) dicesum += 2;
				if (slots[i] == DiceSlotType.FREE3) dicesum += 3;
				if (slots[i] == DiceSlotType.FREE4) dicesum += 4;
				if (slots[i] == DiceSlotType.FREE5) dicesum += 5;
				if (slots[i] == DiceSlotType.FREE6) dicesum += 6;
			}
		}
		
		return dicesum;
	}
	
	public function getshockedpower():Int{
		var dicesum:Int = 0;
		var emptyslots:Int = 0;
		
		if (shocked_countdown > 0){
			dicesum = shocked_countdown;
		}else{
			for (i in 0 ... shocked_assigneddice.length){
				if (shocked_assigneddice[i] != null){
					if (Rules.reunioncoinmode){
						if(shocked_assigneddice[i].value % 2 == 0){
							dicesum += 2;
						}else{
							dicesum += 1;
						}
					}else{
						dicesum += shocked_assigneddice[i].value;
					}
				}else{
					emptyslots++;
				}
			}
		}
		
		return dicesum;
	}

	function reloadtranslations() {
		if(skills != null) {
			for(skill in skills) {
				skill.reloadtranslations();
			}
		}
		if(equipmentpanel != null) {
			equipmentpanel.reloadtranslations();
		}
	}

	var lastlocale = Locale.currentlanguage;
	
	public var name:String;
	public var displayname:String;
	public var rawname:String;
	public var name_beforesubstitution:String;
	public var rawname_beforesubstitution:String;
	public var namemodifier:String;
	public var fulldescription:String;
	public var overwritefinalline:String;
	public var castdirection:Int;
	public var skillcard:String;
	public var skillcard_special:Bool;
	public var stolencard:Bool;
	public var equippedby:Fighter;
	public var gadget:String;
	public var ispowercard:Bool;
	
	public var needstotal:Int;
	public var conditionalslots:Bool;
	
	public var ready:Bool;
	public var active:Bool;
	
	public var size:Int;
	public var x:Float;
	public var y:Float;
	public var initialpos:Point;
	public var finalpos:Point;
	public var row:Int;
	public var column:Int;
	public var displayrow:Int; // these may differ from "row/column" when confused
	public var displaycolumn:Int;

	// render x and y
	var tx:Float = 0;
	var ty:Float = 0;
	
	public var equipmentcol:Int;
	public var temporary_thisturnonly:Bool;
	public var width:Int;
	public var height:Int;
	public var upgradetype:String;
	public var weakentype:String;
	public var upgraded:Bool;
	public var ignoredicevalue:Bool;
	public var onceperbattle:Bool;
	public var removefromthisbattle:Bool;
	public var usedthisbattle:Bool;
	public var needsdoubles:Bool;
	public var combination:Bool;
	public var combinationflash:Float;
	public var locked:Int;
	public var unlocked:Int;
	public var unlockflash:Float;
	public var unlockedthisturn:Bool;
	public var timesused:Int;
	public var totalusesremaining:Int;
	
	public var reuseable:Int;
	public var usesleft:Int;
	public var reuseableanimation:Float;
	public var reuseableoriginalx:Int;
	public var reuseableoriginaly:Int;
	public var tempreuseableequipment:Array<Equipment>;
	
	public var equipalpha:Float;
	public var gamepadalpha:Float;
	
	public var script:String;
	public var scriptbeforestartturn:String;
	public var scriptonstartturn:String;
	public var scriptendturn:String;
	public var scriptbeforecombat:String;
	public var scriptaftercombat:String;
	public var scriptonanyequipmentuse:String;
	public var scriptonanycountdownreduce:String;
	public var scriptbeforeexecute:String;
	public var scriptonsnap:String;
	public var scriptiffury:String;
	public var scriptondodge:String;
	public var onetimecheck:Bool;
	
	public var scriptrunner:DiceyScript;
	public var skills:Array<Skill>;
	public var skillsavailable:Array<Bool>;
	public var skills_temporarythisfight:Array<Bool>;
	
	public var assigneddice:Array<Dice>;
	public var slots:Array<DiceSlotType>;
	public var slotpositions:Array<Point>;
	public var descriptiontextoffset:Int;
	
	public var shakex:Float;
	public var shakey:Float;
	
	public var shocked_assigneddice:Array<Dice>;
	public var shocked_slots:Array<DiceSlotType>;
	public var shocked_slotpositions:Array<Point>;
	public var shocked_textoffset:Float;
	public var shockedtype:String;
	public var shockedsetting:Int;
	public var shockedtext:String;
	public var shockedcol:Int;
	public var shocked_showtitle:Bool;
	public var shocked_returndice:Bool;
	
	public var shocked_remainingcountdown:Int;
	public var shocked_countdown:Int;
	public var shocked_needstotal:Int;
	
	public var unshockingtimer:Float;
	
	public var slotshake:Array<Point>;
	public var flashtime:Float;
	public var weakened:Bool;
	public var originallyupgraded:Bool;
	
	public var charge:Int;
	
	public var aihints:String;
	public var priority:Int;

	public var sfxoverride:String;
	public var playersound:String;
	public var enemysound:String;
	
	public var animation:Array<Animation>;
	
	public function animate(type:String, delay:Float = 0, firstattack:Bool = true){
		var newanimation:Animation = new Animation();
		newanimation.applytoequipment(this);
		animation.push(newanimation);
		
		if (delay > 0){
			newanimation.adddelay(delay);
		}
		
		switch(type){
			case "slotschanged":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0.1, 4, 4);
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Slots changed!") + " [dice]", 0xFFFFFF);
			case "nofit":
				newanimation.addcommand("shake", 0.1, 4, 4);
				newanimation.adddelay(0.1);
				var firstslot:DiceSlotType = null;
				if (slots != null){
					if (slots.length > 0){
						firstslot = slots[0];
					}
				}
				
				if (firstslot == DiceSlotType.MAX1){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 1!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MAX2){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[lilheads] " + Locale.translate("Silver coins only!") + " [lilheads]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 2 or less!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.MAX3){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 3 or less!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MAX4){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 4 or less!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MAX5){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 5 or less!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MIN2){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 2 or more!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MIN3){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 3 or more!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MIN4){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 4 or more!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.MIN5){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[lilheads] " + Locale.translate("Gold coins only!") + " [lilheads]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 5 or more!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.RANGE23){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs 2 or 3!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.RANGE24){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs 2[;] 3[;] or 4!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.RANGE25){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs 2[;] 3[;] 4 or 5!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.RANGE34){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs 3 or 4!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.RANGE35){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs 3[;] 4 or 5!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.RANGE45){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs 4 or 5!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.ODD){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[liltails] " + Locale.translate("Tails only!") + " [liltails]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("1[;] 3 or 5 only!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.EVEN){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[lilheads] " + Locale.translate("Heads only!") + " [lilheads]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("2[;] 4 or 6 only!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.REQUIRE1){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[liltails] " + Locale.translate("Silver coins only!") + " [liltails]", 0xFFFFFF);
					}else{
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 1!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.REQUIRE2){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[lilheads] " + Locale.translate("Silver coins only!") + " [lilheads]", 0xFFFFFF);
					}else{
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 2!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.REQUIRE3){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 3!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.REQUIRE4){
					newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 4!") + " [dice]", 0xFFFFFF);
				}else if (firstslot == DiceSlotType.REQUIRE5){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[liltails] " + Locale.translate("Gold coins only!") + " [liltails]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 5!") + " [dice]", 0xFFFFFF);
					}
				}else if (firstslot == DiceSlotType.REQUIRE6){
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[lilheads] " + Locale.translate("Gold coins only!") + " [lilheads]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Needs a 6!") + " [dice]", 0xFFFFFF);
					}
				}else{
					if (Rules.reunioncoinmode){
						newanimation.addcommand("textparticle", "[lilheads] " + Locale.translate("Coin doesn't fit!") + " [lilheads]", 0xFFFFFF);
					}else{
						newanimation.addcommand("textparticle", "[dice] " + Locale.translate("Dice doesn't fit!") + " [dice]", 0xFFFFFF);
					}
				}
			case "removesilence":
				newanimation.addcommand("flash", 0.2 / BuildConfig.speed);
				newanimation.adddelay(0.2 / BuildConfig.speed);
				newanimation.addcommand("removestatus", Status.SILENCE);
			case "fastdestroy":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("alphafadeout");
				newanimation.adddelay(0.3);
			case "destroy":
				newanimation.addcommand("flash", 0.1);
				newanimation.adddelay(0.1);
				newanimation.addcommand("alphafadeout");
				newanimation.adddelay(0.4);
			case "alternate_poison":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "_poison");
				newanimation.addcommand("textparticle", "[" + Status.POISON + "] " + Locale.translate("Poison") + "?!", Col.WHITE);
				if (equippedby == null){
					trace("Warning: we can't establish the owner of \"" + displayname +"\". Setting Poison? countdown to 6 to avoid a crash.");
					newanimation.addcommand("applyvariable", Status.ALTERNATE + Status.POISON, 6);
				}else{
					newanimation.addcommand("applyvariable", Status.ALTERNATE + Status.POISON, equippedby.getstatus(Status.ALTERNATE + Status.POISON).value);
				}
			case Status.SHOCK:
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_shock_to_equipment");
				newanimation.addcommand("textparticle", "[" + Status.SHOCK + "] " + Locale.translate("Shocked") + Locale.punctuationtranslate("!"), Col.YELLOW);
				newanimation.addcommand("applyvariable", Status.SHOCK);
			case Status.ALTERNATE_SHOCK:
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_shock_to_equipment");
				newanimation.addcommand("textparticle", "[" + Status.SHOCK + "] " + Locale.translate("Shocked") + Locale.punctuationtranslate("?!"), Col.YELLOW);
				newanimation.addcommand("applyvariable", Status.ALTERNATE + Status.SHOCK);
			case Status.SILENCE:
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_silence_to_equipment");
				newanimation.addcommand("textparticle", "[" + Status.SILENCE + "] " + Locale.translate("Silence") + Locale.punctuationtranslate("!"), Col.LIGHTBLUE);
				newanimation.addcommand("applyvariable", Status.SILENCE);
			case Status.WEAKEN:
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_weaken_to_equipment");
				newanimation.addcommand("textparticle", "[" + Status.WEAKEN + "] " + Locale.translate("Weaken") + Locale.punctuationtranslate("!"), 0xDD8E41);
				newanimation.addcommand("applyvariable", Status.WEAKEN);
			case "shock_and_weaken":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_shock_to_equipment");
				newanimation.addcommand("textparticle", "[" + Status.SHOCK + "]" + Locale.translate("Shocked") + " + " + "[" + Status.WEAKEN + "]" + Locale.translate("Weaken") + Locale.punctuationtranslate("!"), Col.WHITE);
				newanimation.addcommand("applyvariable", Status.WEAKEN);
				newanimation.addcommand("applyvariable", Status.SHOCK);
			case "altshock_and_weaken":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_shock_to_equipment");
				newanimation.addcommand("textparticle", "[" + Status.SHOCK + "]" + Locale.translate("Shocked") + "? + " + "[" + Status.WEAKEN + "]" + Locale.translate("Weaken") + Locale.punctuationtranslate("!"), Col.WHITE);
				newanimation.addcommand("applyvariable", Status.WEAKEN);
				newanimation.addcommand("applyvariable", Status.ALTERNATE + Status.SHOCK);
			case "altpoison_and_weaken":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "_poison");
				newanimation.addcommand("textparticle", "[" + Status.POISON + "]" + Locale.translate("Poison") + "? + " + "[" + Status.WEAKEN + "]" + Locale.translate("Weaken") + Locale.punctuationtranslate("!"), Col.WHITE);
				newanimation.addcommand("applyvariable", Status.WEAKEN);
				if (equippedby == null){
					trace("Warning: we can't establish the owner of \"" + displayname +"\". Setting Poison? countdown to 6 to avoid a crash.");
					newanimation.addcommand("applyvariable", Status.ALTERNATE + Status.POISON, 6);
				}else{
					newanimation.addcommand("applyvariable", Status.ALTERNATE + Status.POISON, equippedby.getstatus(Status.ALTERNATE + Status.POISON).value);
				}
			case "cursereverse":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("screenshake");
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", "[" + Status.CURSE + "] " + Locale.translate("Cursed") + Locale.punctuationtranslate("!"), 0xFFFFFF);
				newanimation.addcommand("cursedimage", "on");
				newanimation.adddelay(0.5);
				newanimation.addcommand("cursedimage", "fadeout");
			case Status.CURSE, "error", "delete":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("screenshake");
				newanimation.adddelay(0.1);
				if (type == Status.CURSE){
					newanimation.addcommand("textparticle", "[" + Status.CURSE + "] " + Locale.translate("Cursed") + Locale.punctuationtranslate("!"), 0xFFFFFF);
				}else if (type == "delete"){
					newanimation.addcommand("textparticle", "[" + Status.CURSE + "] " + Locale.translate("Deleted") + Locale.punctuationtranslate("!"), 0xFFFFFF);
				}else if (type == "error"){
					newanimation.addcommand("textparticle", "[" + Status.CURSE + "] " + Locale.translate("Error") + Locale.punctuationtranslate("!"), 0xFFFFFF);
				}
				newanimation.addcommand("alphafadeout");
				newanimation.adddelay(0.1);
				newanimation.addcommand("blackout");
				newanimation.adddelay(0.1);
				newanimation.addcommand("cursedimage", "on", type == "error" ? 1 : 0);
				newanimation.adddelay(0.5);
				newanimation.addcommand("cursedimage", "fadeout");
			case "quickcurse":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("screenshake");
				newanimation.addcommand("alphafadeout");
				newanimation.addcommand("cursedimage", "on", type == "error" ? 1 : 0);
				newanimation.adddelay(0.5);
				newanimation.addcommand("cursedimage", "fadeout");
			case "immuneerror":
				newanimation.addcommand("flash", 0.1);
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", "[" + Status.CURSE + "] " + Locale.translate("Immune") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "shockimmune":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_shock_to_equipment");
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", "[" + Status.SHOCK + "] " + Locale.translate("Immune") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "weakenimmune":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "apply_weaken_to_equipment");
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", "[" + Status.WEAKEN + "] " + Locale.translate("Immune") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "altpoisonimmune":
				newanimation.addcommand("flash", 0.1);
				if(firstattack)	newanimation.addcommand("soundevent", "_poison");
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", "[" + Status.POISON + "] " + Locale.translate("Immune") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "newgadget":
				newanimation.addcommand("flash", 0.1);
				newanimation.adddelay(0.1);
				newanimation.addcommand("textparticle", Locale.translate("New Gadget") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "unlock":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("applyvariable", "unlock");
			case "flash":
				newanimation.addcommand("flash", 0.1);
			case "flashandshake":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0.1, 4, 4);
			case "witchreunion":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0.1, 4, 4);
				newanimation.adddelay(0.35 / (BuildConfig.speed * Settings.animationspeed));
				newanimation.addcommand("textparticle", Locale.translate("Perfect") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "thiefreunion":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("shake", 0.1, 4, 4);
				newanimation.adddelay(0.35 / (BuildConfig.speed * Settings.animationspeed));
				newanimation.addcommand("textparticle", Locale.translate("Stolen") + Locale.punctuationtranslate("!"), 0xFFFFFF);
			case "snap":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("textparticle", Locale.translate("Snap!"), Col.WHITE);
			case "disappear":
				newanimation.addcommand("flash", 0.1);
				newanimation.addcommand("textparticle", Locale.translate("Snap!"), Col.WHITE);
				newanimation.addcommand("alphafadeout");
				newanimation.adddelay(0.1);
		}
	}

	public function preparegadgettooltip() {
		if(gadget == null || gadget == "") return;

		if(gadgettooltip_id != null && TooltipManager.hastooltip(gadgettooltip_id)) {
			return;
		}

		var item:SkillTemplate = Gamedata.getskilltemplate(gadget);
		var tooltipfunc = function() {
			var result = [];
			result.push("");
			result.push(Locale.translate(item.description));
			return result;
		}
		
		var tooltipid:String = 'equipment_${name}${namemodifier}_gadget_${gadget}';
		
		gadgettooltip_id = TooltipManager.addtooltipwithfunc(tooltipid, tooltipfunc, "gadgetpreview", "gamefontsmall", Col.WHITE, Text.CENTER);
		TooltipManager.updatetooltipline(tooltipid, 0, {func: function() return Locale.translate(item.name)}, Col.WHITE, "headerfont", Text.CENTER);
	}
	
	public function dispose(){
		cleardicehistory();

		equipmentpanel.dispose();
		
		if (rustcounter.length > 0){
			for (i in 0 ... rustcounter.length) rustcounter[i].dispose();
			rustcounter = [];
		}
		
		if (skills != null){
			if (skills.length > 0){
				for (i in 0 ... skills.length) skills[i].dispose();
			}
		}
		
		if (showhealthbar){
			healthbar.dispose();
		}

		if(gadgettooltip_id != null) {
			TooltipManager.removetooltip(gadgettooltip_id);
			gadgettooltip_id = null;
		}
	}
	
	public function hastag(tagname:String):Bool{
		if (tags.indexOf(tagname) > -1) return true;
		return false;
	}
	
	public function addtag(tagname:String){
		if (!hastag(tagname)) tags.push(tagname);
	}
	
	public function removetag(tagname:String){
		if (hastag(tagname)) tags.remove(tagname);
	}
	
	public var onanimatecomplete:Function;
	public var onanimatecomplete_selectedslot:Int;
	public var onanimatecomplete_actor:Fighter;
	public var onanimatecomplete_equipment:Equipment;
	public var cursedimage:Float;
	public var useglitch:Bool = false;
	public var blackedout:Bool;
	public var tags:Array<String>;
	
	public var preventdefault:Bool;
	public var maintainfury:Bool;
	public var alreadyfuryed:Bool;
	public var availablethisturn:Bool;
	public var availablenextturn:Bool;
	public var unavailabletext:String;
	public var unavailablemodifier:String;
	public var unavailabledetails:Array<String>;
	public var sourceequipment:Equipment;
	
	public var equipmentpanel:EquipmentPanel;
	public var rustcounter:Array<TinyDiceGraphic>;
	public var damagethisturn:Int;
	public var damagethisscript:Int;
	
	public var allowupdatereuseabledescription:Bool;
	
	//Countdown stuff
	public var remainingcountdown:Int;
	public var countdown:Int;
	public var reducecountdownby:Int;
	public var reducecountdowndelay:Float;
	public var maxcountdown:Int;
	public var alternateburningcountdownslot:Bool;
	public var dicehistory:Array<Dice>;
	
	//Monstermode!
	public var showhealthbar:Bool;
	public var monstercard:Monstermodecard;
	public var healthbar:Healthbar;

	// tooltip for gadget
	var gadgettooltip_id:String = null;
	public static var gadgettooltip_enabled = false;

	inline function clampremainingcountdown(remaining:Int, oldmax:Int, max:Int) {
			var c = Geom.range_lerp(remaining, 0, oldmax, 0, max);
			// clamp 1 to max so we don't have a 0 here and lock the game
			c = Geom.clamp(Math.round(c), 1, max);
			return Std.int(c);
	}
	
	public var maxslots(get, never):Int;
	public function get_maxslots():Int{
		var countslots:Int = 0;
		for (i in 0 ... slots.length){
			//Not counted here: FREE1 through FREE6, SPARE1 through SPARE6, SKILL
			if (slots[i] == DiceSlotType.NORMAL) countslots++;
			if (slots[i] == DiceSlotType.EVEN) countslots++;
			if (slots[i] == DiceSlotType.ODD) countslots++;
			if (slots[i] == DiceSlotType.COUNTDOWN) countslots++;
			if (slots[i] == DiceSlotType.WITCH) countslots++;
			if (slots[i] == DiceSlotType.REQUIRE1) countslots++;
			if (slots[i] == DiceSlotType.REQUIRE2) countslots++;
			if (slots[i] == DiceSlotType.REQUIRE3) countslots++;
			if (slots[i] == DiceSlotType.REQUIRE4) countslots++;
			if (slots[i] == DiceSlotType.REQUIRE5) countslots++;
			if (slots[i] == DiceSlotType.REQUIRE6) countslots++;
			if (slots[i] == DiceSlotType.MAX1) countslots++;
			if (slots[i] == DiceSlotType.MAX2) countslots++;
			if (slots[i] == DiceSlotType.MAX3) countslots++;
			if (slots[i] == DiceSlotType.MAX4) countslots++;
			if (slots[i] == DiceSlotType.MAX5) countslots++;
			if (slots[i] == DiceSlotType.MIN2) countslots++;
			if (slots[i] == DiceSlotType.MIN3) countslots++;
			if (slots[i] == DiceSlotType.MIN4) countslots++;
			if (slots[i] == DiceSlotType.MIN5) countslots++;
			if (slots[i] == DiceSlotType.RANGE23) countslots++;
			if (slots[i] == DiceSlotType.RANGE24) countslots++;
			if (slots[i] == DiceSlotType.RANGE25) countslots++;
			if (slots[i] == DiceSlotType.RANGE34) countslots++;
			if (slots[i] == DiceSlotType.RANGE35) countslots++;
			if (slots[i] == DiceSlotType.RANGE45) countslots++;
			if (slots[i] == DiceSlotType.DOUBLES) countslots++;
			if (slots[i] == DiceSlotType.LOCKED2) countslots++;
			if (slots[i] == DiceSlotType.LOCKED3) countslots++;
			if (slots[i] == DiceSlotType.LOCKED4) countslots++;
			if (slots[i] == DiceSlotType.LOCKED5) countslots++;
			if (slots[i] == DiceSlotType.LOCKED6) countslots++;
			if (slots[i] == DiceSlotType.LOCKED7) countslots++;
			if (slots[i] == DiceSlotType.COMBINATION) countslots++;
		}
		
		return countslots;
	}
	
	public function isready(?_allowunavailable:Bool=false):Bool{
		if (stolencard) {
			if (equippedby != null) {
				return equippedby.stolencard.isready();
			} else {
				return false;
			}
		}

		if (!active || (!_allowunavailable && !availablethisturn)) {
			return false;
		}

		if (skillcard == "jester" && maxslots == 0) {
			return false;
		}
		
		if (skillcard != "" && maxslots == 0 && skills.length > 0) {
			var canuseskills:Bool = false;
			for (s in skills) {
				if (s.passrequirement(Game.player, Game.monster)) {
					canuseskills = true;
				}
			}
			if (!canuseskills) {
				return false;
			}
		}
		
		if (countdown > 0 && remainingcountdown - reducecountdownby <= 0) {
			return false;
		}
		
		return ready;
	}
	
	public function willbecomeready(?_allowunavailable:Bool = false):Bool{
		if (equippedby == null){
		  //This variable is supposed to be set before it's equipped, but in some
			//cases it isn't, and that will cause a crash here. This check prevents
			//the crash by figuring out who it's currently equipped by
			equippedby = Game.fixequippedbyfield(this);
			//If it's still null, uff, just return false to prevent a crash
			if (equippedby == null) return false;
		}
		
		if (stolencard) {
			if (equippedby != null) {
				return equippedby.stolencard.willbecomeready();
			} else {
				return false;
			}
		}

		if (!active || (!_allowunavailable && !availablethisturn)) {
			return false;
		}

		if (skillcard == "jester" && maxslots == 0) {
			return false;
		}

		if (skillcard != "" && maxslots == 0 && skills.length > 0) {
			var canuseskills:Bool = false;
			for (s in skills) {
				if (s.passrequirement(Game.player, Game.monster)) {
					canuseskills = true;
				}
			}
			if (!canuseskills) {
				return false;
			}
		}
		
		if (countdown > 0 && remainingcountdown - reducecountdownby <= 0) {
			return reuseable != 0 && usesleft != 0 || equippedby.hasstatus(Status.RECYCLE);
		}
		
		return ready;
	}
	
	public function iscurrentlylocked():Bool{
		return locked > 0 && locked - unlocked > 0 && !unlockedthisturn;
	}
	
	public function currentlyreducingcountdown():Bool{
		if (countdown > 0){
			if (reducecountdownby > 0){
				return true;
			}
		}
		return false;
	}
	
	public function containsadicealready():Bool{
		//Returns true if this piece of equipment already contains a dice
		if (assigneddice != null){
			if (assigneddice.length > 0){
				for (i in 0 ... assigneddice.length){
					if (assigneddice[i] != null) return true;
				}
			}
		}
		return false;
	}

	public function verticallycentred():Bool{
		var equipcentrey:Float;
		
		if (finalpos != null) {
			equipcentrey = finalpos.y + 0.5 * height;
		} else {
			equipcentrey = y + 0.5 * height;
		}
		
		return Math.abs(equipcentrey - Screen.heightmid) < 0.3 * height;
	}
	
	public function onscreen():Bool{
		if (x + width < 0) return false;
		if (x > Screen.width) return false;
		if (y + height < 0) return false;
		if (y > Screen.height) return false;
		
		return true;
	}
	
	public function resetfornewturn(_turn:String){
		show = true;
		if (removefromthisbattle){
			ready = false;
		}else	if (onceperbattle && usedthisbattle){
			ready = false;
		}else{
			ready = true;
		}
		active = true;
		equipalpha = 1.0;
		blackedout = false;
		preventdefault = false;
		maintainfury = false;
		alreadyfuryed = false;
		
		shockedtype = "NORMAL";
		shockedsetting = 0;
		shockedtext = "";
		shocked_textoffset = 0;
		shockedcol = Pal.BLACK;
		shocked_showtitle = true;
		shocked_returndice = false;
		shocked_needstotal = 0;
		
		cursedimage = 0;
		useglitch = false;
		if (reuseable != 0){
			usesleft = reuseable;
			updatereuseabledescription();
		}
		tempreuseableequipment = [];
		removedice();
		if(_turn == "player"){
			x = -(width + 50);
		}else{
			x = Screen.width;
		}
		
		alternateburningcountdownslot = false;
	}
	
	public function cleardicehistory(){
		alternateburningcountdownslot = false;
		if(dicehistory == null){
			dicehistory = []; 
		}else{
			for (d in dicehistory){
				if (d != null) d.dispose();
			}
			dicehistory = [];
		}
	}
	
	public function resetvar(v:String = ""){
		if(v == ""){
			gamevar = new Map<String, Dynamic>();
		}else{
			if (gamevar == null){
				gamevar = new Map<String, Dynamic>();
				return;
			}
			
			if (gamevar.exists(v)){
				gamevar.remove(v);
			}
		}
	}
	public function getvar(v:String):Dynamic{
		if (gamevar != null){
			if (gamevar.exists(v)){
				return gamevar.get(v); 
			} 
		} 
		
		return 0; 
	}
	
	public function setvar(v:String, newvalue:Dynamic){
		if (gamevar == null) gamevar = new Map<String, Dynamic>();
		gamevar.set(v, newvalue);
	}
	
	public function varexists(v:String):Bool {
		if (gamevar == null) return false;
		return gamevar.exists(v);
	}
	
	public var gamevar:Map<String, Dynamic>;
	
	public function setmonstercard(m:Monstermodecard){
		showhealthbar = true;
		monstercard = m;
		healthbar = new Healthbar();
	}
	
	public function resetskillsfornewturn(){
		if(skills.length > 0){
			for (j in 0 ... skills.length){
				if(skills[j].rechargeeveryround){
					skillsavailable[j] = true;
				}
			}
		}
	}
	
	public function resetaftercombat(){
		if (countdown > 0){
			remainingcountdown = countdown;
		}
		usedthisbattle = false;
		charge = 0;
		timesused = 0;
		availablethisturn = true;
		availablenextturn = true;
		unavailabletext = "Unavailable";
		unavailablemodifier = "";
		unavailabledetails = [];
		/*
		if (hastag("deckofwonder")){
			trace(name + " is reverting to Deck of Wonder now");
			equipmentpanel.dispose();
			equipmentpanel = null;
			initvariables();
			resetvar();
			create("Deck of Wonder", upgraded, false);
		}*/
	}
	
	public var slotsfree(get, never):Int;
	public function get_slotsfree():Int{
		return maxslots - getnumassigneddice();
	}
	
	public var shockedslotsfree(get, never):Int;
	public function get_shockedslotsfree():Int{
		return shocked_slots.length - getnumassignedshockeddice();
	}
	
	public function toString():String{
		return name + namemodifier;
	}
	
	public var show:Bool;
	
	public var applyequipmentstatus:String;
	
	static var gamepadcursor_small1:HaxegonSprite = null;
	static var gamepadcursor_small2:HaxegonSprite = null;
	static var gamepadcursor_large:HaxegonSprite = null;
	static var gamepadcursor2_small1:HaxegonSprite = null;
	static var gamepadcursor2_small2:HaxegonSprite = null;
	static var gamepadcursor2_large:HaxegonSprite = null;
}