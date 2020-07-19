package elements;

import states.*;
import haxegon.*;
import characters.*;
import displayobjects.*;
import elements.templates.*;
import flash.geom.Point;
import lime.ui.GamepadButton;
import motion.Actuate;
import haxe.Utf8;
import elements.Deck.DeckPublic;
import elements.Spellbook.SpellbookPublic;

class TurnHistory{
	public function new(f:Fighter, _when:String){
		hp = f.hp;
		when = _when;
		//limitvalue = f.limitvalue;
		
		status = [];
		for (i in 0 ... f.status.length){
			status.push(f.status[i].clone());
		}
	}
	
	public function dispose(){
		//Not actually needed right now
		/*
		if (status != null){
			for (i in 0 ... status){
				//status[i].dispose();
			}
		}*/
	}
	
	public function restore(f:Fighter){
		f.hp = hp;
		//f.limitvalue = limitvalue;
		
		f.status = [];
		for (i in 0 ... status.length){
			f.status.push(status[i].clone());
		}
	}
	
	public var hp:Int;
	//public var limitvalue:Int;
	public var status:Array<StatusEffect>;
	public var when:String;
}

class Fighter{
	public function new(_type:String, makesuper:Bool, ?customtemplate:FighterTemplate = null){
		type = _type.toLowerCase();
		name = _type;
		namelength = -1;
		x = 0;
		y = 0;
		particlex = 0;
		particley = 0;
		
		textboxes = [];
		textboxesaudio = [];
		initvariables();
		resetvar();
		
		if (customtemplate != null){
			template = customtemplate;
		}else{
			template = Gamedata.getfightertemplate(name);
			if (template == null) throw("Error: Cannot find fighter template for \"" + name + "\"");
		}
		name = template.name;
		namelength = -1;
		description = template.name;
		voice = template.voice;
		chatvoice = template.chatvoice;
		
		var healthoverwrite:Bool = false;
		if (Rules.enemyhpchanges != null){
			if (Rules.enemyhpchanges.exists(name)){
				healthoverwrite = true;
			}
		}
		
		if (healthoverwrite){
	    maxhp = Rules.enemyhpchanges.get(name);
		}else{
		  maxhp = template.health;
		}
		
		scriptbeforecombat = template.scriptbeforecombat;
		scriptaftercombat = template.scriptaftercombat;
		scriptbeforestartturn = template.scriptbeforestartturn;
		scriptonstartturn = template.scriptonstartturn;
		scriptendturn = template.scriptendturn;
		maxmana = 100;
		
		var diceoverwrite:Bool = false;
		if (Rules.enemydicechanges != null){
			if (Rules.enemydicechanges.exists(name)){
				diceoverwrite = true;
			}
		}
		
		if(diceoverwrite){
			dice = Rules.enemydicechanges.get(name);
		}else{
			dice = template.dice;
		}
		
		bonusdice = 0;
		extradice = 0;
		bonusdicenextturn = 0;
		
		var leveloverwrite:Bool = false;
		if (Rules.enemylevelchanges != null){
			if (Rules.enemylevelchanges.exists(name)){
				leveloverwrite = true;
			}
		}
		
		if (leveloverwrite){
			level = Rules.enemylevelchanges.get(name);
		}else{
			level = template.level;
		}
		
		fightswon = 0;
		fightsfled = 0;
		lastwordstate = 0;
		lastwords_selected = "";
		firstwordstate = 0;
		firstwords_selected = "";
		layout = EquipmentLayout.EQUIPMENT;
		
		canspeaklastwords = false;
		alwaysspeaklastwords = false;
		lastwords1 = "";
		lastwords2 = "";
		lastwords3 = "";
		lastwords_iftheywin = "";
		lastwords_endgame = "";
		if (template.lastwords1 != ""){
			lastwords1 = template.lastwords1;
			canspeaklastwords = true;
		}
		if (template.lastwords2 != ""){
			lastwords2 = template.lastwords2;
			canspeaklastwords = true;
		}
		if (template.lastwords3 != ""){
			lastwords3 = template.lastwords3;
			canspeaklastwords = true;
		}
		if (template.lastwords_iftheywin != ""){
			lastwords_iftheywin = template.lastwords_iftheywin;
			canspeaklastwords = true;
		}
		if (template.lastwords_endgame != ""){
			lastwords_endgame = template.lastwords_endgame;
			canspeaklastwords = true;
		}
		if (template.alwayssaylastwords == true){
			alwaysspeaklastwords = true;
		}
		
		canspeakfirstwords = false;
		alwaysspeakfirstwords = false;
		firstwords = "";
		if (template.firstwords != ""){
			firstwords = template.firstwords;
			canspeakfirstwords = true;
		}
		if (template.alwayssayfirstwords == true){
			alwaysspeakfirstwords = true;
			canspeakfirstwords = true;
		}
		
		combatstatoffset = 0;
		vfxoffset = new Point(template.vfxoffset.x, template.vfxoffset.y);
		
		if (makesuper){
			hassuper = true;
			dice += template.superdice;
			maxhp += template.superhealth;
		}
		
		finderskeepers = 0;
		
		ai = template.ai;
		
		limitbreak = null;
		if(template.limit != ""){
			limitbreak = new Skill(template.limit, 0);
			alternatelimitbreak = new Skill(template.alternatelimit, 0);
			if (limitbreak != null){
				limitmax = Std.int((maxhp / 3));
				limitvalue = 0;
			}
			
			if(Episodestate.activeepisode != null){
				layout = Episodestate.activeepisode.layout;
			}else{
				layout = EquipmentLayout.EQUIPMENT;
			}
		}
		
		innate = [];
		
		var innateoverwrite:Bool = false;
		if (Rules.enemyinnatechanges != null){
			if (Rules.enemyinnatechanges.exists(name)){
				innateoverwrite = true;
			}
		}
		
		if (innateoverwrite){
			var overrideinnate:Array<String> = Rules.enemyinnatechanges.get(name);
			for (i in 0 ... overrideinnate.length){
				innate.push(overrideinnate[i]);
			}
		}else{
			for (i in 0 ... template.innate.length){
				innate.push(template.innate[i]);
			}
		}
		
		innatetriggered = 0;
		innateypos = -30 * 6;
		
		if (layout == EquipmentLayout.DECK){
			//Jester has a different take on equipment
			equipment = [];
			Deck.reset();
			for (i in 0 ... template.equipment.length){
				Deck.addtodiscard(Deck.createcard(template.equipment[i]));
		  }
		}else if (layout == EquipmentLayout.SPELLBOOK){
			//Witch spells are assigned from equipment in template
			Spellbook.reset();
			for (i in 0 ... template.equipment.length){
				if (template.equipment[i] != "empty"){
					if (S.isinstring(template.equipment[i], "*")){
						Spellbook.learnspell(S.removefromstring(template.equipment[i], "*"), i + 1);
						Spellbook.precast[0] = i;
						Spellbook.availableslots[0] = true;
					}else{
						Spellbook.learnspell(template.equipment[i], i + 1);
					}
				}
		  }
			
			if (Spellbook.spells[Spellbook.spells.length - 1] != null){
				if (Spellbook.spells[Spellbook.spells.length - 1].name == ""){
				  SpellbookPublic.showspellbookinstructions = true;
				}
			}
		}else{
			var firstskill:String = "";
			if (template.skills.length > 0){
				firstskill = template.skills[0];
			}
			if (firstskill == "Monstermode"){
				//A special case: Monster mode isn't exactly a new layout, but it does need to
				//override a lot of default behaviour.
				Monstermode.newrun();
				equipment = [];
				for (i in 0 ... template.equipment.length){
					Monstermode.add(template.equipment[i], false);
				}
			}else{
				var equipmentoverwrite:Bool = false;
				if (Rules.enemyequipmentchanges != null){
					if (Rules.enemyequipmentchanges.exists(name)){
						equipmentoverwrite = true;
					}
				}
				
				if (equipmentoverwrite){
					var newequipmentlist:Array<String> = Rules.enemyequipmentchanges.get(name);
					for (i in 0 ... newequipmentlist.length){
						equipment.push(new Equipment(newequipmentlist[i]));
					}
				}else{
					if (hassuper){
						for (i in 0 ... template.superequipment.length){
							equipment.push(new Equipment(template.superequipment[i]));
						}
					}else{
						for (i in 0 ... template.equipment.length){
							equipment.push(new Equipment(template.equipment[i]));
						}
					}
				}
			}
		}
		
		hp = maxhp;
		mana = maxmana;
		
		graphic = null;
		graphicanimated = false;
		shadow = null;
		
		//We're a monster!
		particlex = 640;
		particley = 260;
		particledir = 1;

		battlevfx = new BattleVFX();
		
		//Apply player status to certain fighters:
		if(template.skills.length > 0){
			createplayer(template);
		}else{
			isplayer = false;
		}
	}
	
	public function createplayer(fightertemplate:FighterTemplate){
		isplayer = true;
		
		particlex = 60;
		particley = 200;
		particledir = 1;
		
		hasstolencard = false;
		stolencard = null;
		var firstskill:String = "";
		var skills = fightertemplate.skills.copy();
		if (skills.length > 0){
			firstskill = S.trimspaces(skills.shift());
		}

		var skillcard = createskillcard(firstskill, skills);
		if(skillcard != null) {
			equipment.push(skillcard);
		}
	}
	
	/* A kludge to fix broken skillcards: move the skillcard to the end of equipment, if it's not there already*/
	public function fixskillcard(){
		var skillcard:Equipment = getskillcard();
		if(skillcard != null){
			equipment.remove(skillcard);
			equipment.push(skillcard);
		}
	}

	public function createskillcard(firstskill:String, skills:Array<String>):Equipment {
		var skillcard:Equipment;
		
		//Special cases: no skillcard, or playing the monstermode episode.
		if (firstskill == "Monstermode"){
			Rules.monstermode = true;
			Rules.levelup_giveleveluprewards = false;
			//Dungeon.locationarrow = true; //Nah never mind
			return null;
		}else	if (firstskill == "Nothing"){
			return null;
		}
		
		//Catch some special hardcoded cases
		skillcard = new Equipment(firstskill);
		skillcard.category = ItemCategory.SKILLCARD;
		skillcard.equippedby = this;
		if (firstskill == "Thief Stolen Card"){
			skillcard.skillcard = "stolencard";
			
			hasstolencard = true;
			skillcard.stolencard = true;
			skillcard.skillcard_special = true;
		}else if (firstskill == "Robot Calculate"){
			roll_target = Rules.robot_startingcpu;
			skillcard.skillcard = "robot_calculate";
			skillcard.skillcard_special = true;
			skillcard.height = 180 * 6;
			if(skillcard.equipmentpanel != null) skillcard.equipmentpanel.remove();
			skillcard.equipmentpanel = new RobotCalculatePanel();
		}else if (firstskill == "Robot Request"){
			skillcard.skillcard = "robot_request";
			skillcard.skillcard_special = true;
			skillcard.height = 180 * 6;
			if(skillcard.equipmentpanel != null) skillcard.equipmentpanel.remove();
			skillcard.equipmentpanel = new RobotRequestPanel();
		}else if (firstskill == "Inventor Gadgets"){
			skillcard.skillcard = "inventor";
			skillcard.skillcard_special = true;
			skillcard.height = 135 * 6 - 57 * 6;
			if (BuildConfig.debug_testgadgets.length > 0){
				skills = []; for (gadget in BuildConfig.debug_testgadgets) skills.push(gadget);
			}
			for (i in 0 ... skills.length){
				skillcard.skills.push(new Skill(skills[i], 22 + (i * 40)));
			}
		}else if (firstskill == "Witch Spellbook"){
			skillcard.skillcard = "witch";
			skillcard.skillcard_special = true;
			skillcard.width = (132 + 20) * 6;
			skillcard.height = 980 + 49 * 6;
			if(skillcard.equipmentpanel != null) skillcard.equipmentpanel.remove();
			skillcard.equipmentpanel = new WitchSpellbookPanel();
			
			skillcard.addslots(DiceSlotType.WITCH, 1);
			skillcard.assigneddice.push(null);
			skillcard.arrangeslots();
		}else if (firstskill == "Jester Deck"){
			skillcard.skillcard = "jester";
			skillcard.skillcard_special = true;
			skillcard.width = 132 * 6;
			skillcard.height = 150 * 6;
			
			if(skillcard.equipmentpanel != null) skillcard.equipmentpanel.remove();
			skillcard.equipmentpanel = new DeckPanel();
		}else if (firstskill == "Witch Deck"){
			skillcard.skillcard = "jester";
			skillcard.skillcard_special = true;
			skillcard.width = 132 * 6;
			skillcard.height = 150 * 6;
			
			if(skillcard.equipmentpanel != null) skillcard.equipmentpanel.remove();
			skillcard.equipmentpanel = new DeckPanel();
			DeckPublic.snapstyle = "witch";
		}else if (firstskill != ""){
			skillcard.makeskillcard();
		}
		
		//Jester doesn't actually "equip" thier skill card
		if(layout == EquipmentLayout.DECK){
			Deck.skillcard = skillcard;
			skillcard.x = Screen.width + 10 * 6; skillcard.y = 0;
		}
		
		if (skillcard != null){
			for (i in 0 ... skillcard.skills.length){
				skillcard.skillsavailable.push(true);
				skillcard.skills_temporarythisfight.push(false);
			}
		}

		return skillcard;
	}
	
	public function replaceskillcard(newcard:String, newe:Equipment = null){
		for (i in 0 ... equipment.length){
			if (equipment[i].skillcard != ""){
				var oldreuseableequipment:Array<Equipment> = equipment[i].tempreuseableequipment;
				var oldx:Float = equipment[i].x;
				var oldy:Float = equipment[i].y;
				var oldrow:Int = equipment[i].displayrow;
				var oldcolumn:Int = equipment[i].displaycolumn;
				var washighlighted:Bool = Combat.gamepad_selectedequipment == equipment[i] || Combat.gamepad_lastequipment == equipment[i];
				equipment[i].dispose();
				if (newe != null){
					equipment[i] = newe;
				}else{
					equipment[i] = new Equipment(newcard);
				}
				
				equipment[i].category = ItemCategory.SKILLCARD;
				equipment[i].equippedby = this;
				equipment[i].makeskillcard();
				//Make sure it's offscreen
				equipment[i].allowupdatereuseabledescription = false;
				equipment[i].x = oldx;
				equipment[i].y = oldy;
				equipment[i].finalpos = new Point(oldx, oldy);
				equipment[i].displayrow = oldrow;
				equipment[i].displaycolumn = oldcolumn;
				equipment[i].tempreuseableequipment = oldreuseableequipment; // Transfer this to keep any temp equipment alive
				
				if (washighlighted) {
					Combat.gamepad_selectedequipment = equipment[i];
				}
			}
		}
	}
	
	public function getskillcard():Equipment{
		for (i in 0 ... equipment.length){
			if (equipment[i].skillcard != ""){
				return equipment[i];
			}
		}
		return null;
	}

	public function isskillcard(skillcard:String) {
		var card = getskillcard();
		if(card != null) {
			return card.skillcard == skillcard;
		}
		return false;
	}
	
	public function endturn(){
		Innate.check(this, "endturn");
		
		if (LadyLuckEnemy.active){
			if(!isplayer)	LadyLuckEnemy.endturn(this);
		}
		
		//Discard unused dice
		for (i in 0 ... dicepool.length){
			dicepool[i].dispose();
			dicepool[i] = null;
		}
		dicepool = [];
		
		//Bonus dice are lost, unless reserved for next turn
		bonusdice = bonusdicenextturn;
		bonusdicenextturn = 0;
		
		if (layout == EquipmentLayout.DECK){
			Deck.endturn(this);
		}else{
			scraptemporaryequipment();
		}
		
		if (Rules.monstermode){
			if(isplayer){
				Monstermode.endturn(this);
			}
		}
		
		Combat.scriptstate = "endturn";
		ProgressTracking.endturnchecks();
		
		runendturnscripts();
		
		Combat.scriptstate = "fight";
		
		StatusApply.endturn(this);
		
		//Certain status effects disappear at the end of your turn
		var i:Int = 0;
		while (i < status.length){
			if (status[i].remove_at_endturn){
				if (status[i].selfinflicted){
					//Self inflicted status effects stick around an extra turn
					status[i].selfinflicted = false;
				}else{
					TooltipManager.removetooltip((isplayer?"player":"enemy") + "_" + status[i].type);
					onstatusremove(status[i].type);
					status.splice(i, 1);
					i--;
				}
			}
			i++;
		}
		
		saveturnhistory("startturn");
	}
	
	public function runendturnscripts(){
		Script.rungamescript(scriptendturn, "fighter_scriptendturn", this);
		
		if (Rules.extrascript_endturn.length > 0){
			if(Game.player == this){
				for (i in 0 ... Rules.extrascript_endturn.length){
					Script.rungamescript(Rules.extrascript_endturn[i], "fighter_scriptendturn", this);
				}
			}
		}
		
		for (e in equipment) e.onetimecheck = false;
		for (e in equipment){
			if (!e.onetimecheck){
				e.onetimecheck = true;
				Script.rungamescript(e.scriptendturn, "equipment_scriptendturn", this, e);
			}
		}
		
		//Status effects endturn scripts
		for (i in 0 ... status.length){
			if (status[i].value > 0) status[i].runscript("endturn", 0);
		}
	}
	
	public function scraptemporaryequipment(){
		//Do we have any temporary equipment? Scrap it.
		var i:Int = 0;
		while (i < equipment.length){
			if (equipment[i].temporary_thisturnonly){
				equipment[i].dispose();
				equipment.splice(i, 1);
			}else{
				i++;
			}
		}
	}
	
	public function reset_readynextturn(){
		//Implement alternate fury's equipment disabling
		for (i in 0 ... equipment.length){
			equipment[i].availablethisturn = true;
			if (!equipment[i].availablenextturn){
				equipment[i].availablenextturn = true;
				equipment[i].availablethisturn = false;
			}
		}
	}
	
	public function checklockedequipment(){
		for (e in equipment){
			if (e.locked > 0 && !e.unlockedthisturn){
				e.unlocked = roll_totaldice;
				e.unlockflash = 1;
			}
		}
	}
	
	public function prepequipment(){
		//Undo weaken status
		if(layout == EquipmentLayout.DECK){
			Deck.unweakenall(this);
		}else{
			for (i in 0 ... equipment.length){
				equipment[i].unweaken();
				equipment[i].damagethisturn = 0;
				equipment[i].damagethisscript = 0;
			}			
		}
		
		//Monster single use equipment is REMOVED completely at this point
		if (Combat.turn == "monster"){
			var i:Int = 0;
			while (i < equipment.length){
				if (equipment[i].onceperbattle && equipment[i].usedthisbattle){
					equipment[i].dispose();
					equipment.splice(i, 1);
					i--;
				}
				i++;
			}
		}
		
		if (Combat.turn == "player"){
			//Remove rusted equipment completely for inventor quest
			if (Rules.inventor_equipmentrust > 0){
				var i:Int = 0;
				var resetinventory = false;
				while (i < equipment.length){
					if (equipment[i].totalusesremaining == -1){
						if (equipment[i].skillcard == "inventor"){
							equipment[i].totalusesremaining = 0;
						}else{
							equipment[i].dispose();
							equipment.splice(i, 1);
							i--;
							
							resetinventory = true;
						}
					}
					i++;
				}
				// Needed for saving
				if(resetinventory) {
					Inventory.reset();
				}
			}
		}
		
		if (layout == EquipmentLayout.DECK){
			Deck.resetallcardsfornewturn(this, Combat.turn);
			Deck.skillcard.resetfornewturn(Combat.turn);
		}else{
			if (isplayer && !Rules.equipmentrechargesbetweenturns){
				//Don't reset equipment!
			}else{
				for (i in 0 ... equipment.length){
					equipment[i].resetfornewturn(Combat.turn);
				}
			}
		}
	}
	
	public function startturn(){
		saveturnhistory("startturn");
		equipmenthistory = [];
		
		if (Game.player == this) {
			Combat.turn = "player";
			if(Game.rules_stackplayerdice_resetsequence){
				Game.rules_stackplayerdice_index = 0;
			}
			
			//Reduce flee delay
			Combat.fleedelay--;
			Combat.turncount++;
			
			Rules.movelimit_current = Rules.movelimit;
		}else{
			Combat.turn = "monster";
			if(Game.rules_stackenemydice_resetsequence){
				Game.rules_stackenemydice_index = 0;
			}
		}
		
		if (LadyLuckEnemy.active){
			if(!isplayer)	LadyLuckEnemy.startturn(this);
		}
		
		ProgressTracking.startturnchecks();
		Gadget.startturn(); //Should do nothing for non-inventors
		Game.throwndicecount = 0;
		Game.throwndicedamage = 0;
		
		doendturnnow = false;
		//Reset Robot settings
		roll_total = 0;
		roll_totaldice = 0;
		roll_realtotal = 0;
		roll_barposition = 0;
		roll_jackpot = 0;
		roll_offset = 0;
		roll_range = 0;
		roll_error = false;
		roll_jackpotbonus = 1;
		if (usecpuinsteadofdice){
			Game.robotrelockequipment(this);
		}
		
		//Reset Jester
		if(layout == EquipmentLayout.DECK){
			Deck.updatejestersnapstyle("discard");
		}
		
		//Clean up dicepool
		if(dicepool != null){
			for (i in 0 ... dicepool.length){
				dicepool[i].dispose();
				dicepool[i] = null;
		  }
		}
		dicepool = [];
		
		//Ready equipment again
		lastequipmentused = null;
		
		if (layout == EquipmentLayout.SPELLBOOK){
			if (Combat.turncount == 1){
				Spellbook.initpreparedspells(this);
			}
			var sorceresscheck:Int = 0;
			for (i in 0 ... Rules.witch_randomspellslot.length){
				if (Rules.witch_randomspellslot[i].length > 0) sorceresscheck++;
			}
			if (sorceresscheck > 0){
				Spellbook.cleanupsorceress();
			}
			Spellbook.startturn();
		}
		
		prepequipment();
		reset_readynextturn();
		
		//Certain status effects disappear at the start of your turn
		var i:Int = 0;
		while (i < status.length){
			if (status[i].remove_at_startturn){
				if (status[i].selfinflicted){
					//Self inflicted status effects stick around an extra turn
					status[i].selfinflicted = false;
				}else{
					onstatusremove(status[i].type);
					TooltipManager.removetooltip((isplayer?"player":"enemy") + "_" + status[i].type);
					status.splice(i, 1);
					i--;
				}
			}
			i++;
		}
		
		if (hasstatus(Status.CONFUSE)){
			Combat.isconfused = true;
		}else{
			Combat.isconfused = false;
		}
		
		//Ready skills
		if (layout == EquipmentLayout.DECK){
			Deck.resetskillsfornewturn(this);
		}else{
			for (i in 0 ... equipment.length){
				equipment[i].resetskillsfornewturn();
			}
		}
		
		//Restart equipment count
		equipmentused = 0;
		
		//Do we have a stolencard? Then we need to prep it!
		if (hasstolencard){
			var enemyequipment:Array<String> = [];
			var target:Fighter;
			if (Game.monster == this){
				target = Game.player;
			}else{
				target = Game.monster;
			}
			for (i in 0 ... target.equipment.length){
				if(!target.equipment[i].hastag("cannotsteal")){
					enemyequipment.push(target.equipment[i].name_beforesubstitution + target.equipment[i].namemodifier);
				}
			}
			
			if (enemyequipment.length > 0){
				Random.shuffle(enemyequipment);
				var tempequipname:String = Random.pick(enemyequipment);
				if (S.isinstring(tempequipname, "-")){
					tempequipname = S.trimspaces(S.getroot(tempequipname, "-"));
				}
				stolencard = new Equipment(tempequipname);
				
				if (stolencard.countdown > 0){
					//Hey, we grabbed a countdown! Let's check if we've used this before
					if (Combat.countdownmemory.exists(stolencard.name)){
						stolencard.remainingcountdown = Combat.countdownmemory.get(stolencard.name);
					}
				}
				
				stolencard.ready = true;
				stolencard.equippedby = this;
				stolencard.shockedtype = DiceSlotType.NORMAL;
				stolencard.shockedsetting = 0;
				stolencard.removedice();
				stolencard.initialpos = new Point(0, 0);
				stolencard.finalpos = new Point(0, 0);
				if (Combat.turn == "player"){
					for (i in 0 ... equipment.length){
						if (equipment[i].stolencard){
							stolencard.initialpos.x = stolencard.finalpos.x = stolencard.x = equipment[i].x;
							stolencard.y = -(equipment[i].height * 1.5);
						}
					}
				}else{
					for (i in 0 ... equipment.length){
						if (equipment[i].stolencard){
							stolencard.initialpos.x = stolencard.finalpos.x = stolencard.x = equipment[i].x;
							stolencard.y =  Screen.height + (equipment[i].height * 0.5);
						}
					}
				}
				
				if (stolencard.size == 2 || stolencard.size == 4){
					stolencard.finalpos.y = stolencard.initialpos.y = Screen.heightmid - (stolencard.height / 2);
				}else{
					stolencard.finalpos.y = stolencard.initialpos.y = Screen.heightmid - (stolencard.height / 2);
				}
				
				Actuate.tween(stolencard, 0.5 / (BuildConfig.speed * Settings.animationspeed), { y: stolencard.finalpos.y })
				  .delay(1.6 / BuildConfig.speed);
			}
		}
		
		if (layout == EquipmentLayout.SPELLBOOK){
			//Reset skillcard
			var s:Equipment = getskillcard();
		}else if (usecpuinsteadofdice){
			//Reset skillcard
			var s:Equipment = getskillcard();
			if(s != null){
				if (s.name == "Robot Request"){
					cast(s.equipmentpanel, RobotRequestPanel).clearhistory();
				}
			}
		}
		
		if (Rules.monstermode){
			if(isplayer){
				Monstermode.startturn(this);
			}
		}
		
		for(e in equipment){
			createsparedice(e);
		}
		
		// Reset gamepad positions each turn.
		if (Game.player == this) {
			Combat.gamepad_dicemode = false;
			Combat.gamepad_buttonmode = false;
			Combat.gamepad_selectedequipment = (equipment.length >= 1) ? equipment[0] : null;
			Combat.gamepad_selecteddice = (dicepool.length >= 1) ? dicepool[0] : null;
			Combat.gamepaddicetrail_prevdice = Combat.gamepad_selecteddice;
			Combat.gamepad_preferredrow = 0;
			Combat.gamepad_deckcolumn = 0;
			
			// Clear the 'last action' data.
			Combat.gamepad_lastequipment = null;
		}
		
		runbeforestartturnscripts();
		
		Innate.check(this, "startturn");
	}
	
	public function runbeforestartturnscripts(){
		Script.rungamescript(scriptbeforestartturn, "fighter_scriptbeforestartturn", this);
		
		if (Rules.extrascript_beforestartturn.length > 0){
			if(Game.player == this){
				for (i in 0 ... Rules.extrascript_beforestartturn.length){
					Script.rungamescript(Rules.extrascript_beforestartturn[i], "fighter_scriptbeforestartturn", this);
				}
			}
		}
		
		if (layout == EquipmentLayout.DECK){
			for (c in Deck.discardpile) c.equipment.onetimecheck = false;
			for (c in Deck.discardpile){
				if (!c.equipment.onetimecheck){
					c.equipment.onetimecheck = true;
					Script.rungamescript(c.equipment.scriptbeforestartturn, "equipment_scriptbeforestartturn", this, c.equipment);
				}
			}
			
			for (c in Deck.inplaypile) c.equipment.onetimecheck = false;
			for (c in Deck.inplaypile){
				if (!c.equipment.onetimecheck){
					c.equipment.onetimecheck = true;
					Script.rungamescript(c.equipment.scriptbeforestartturn, "equipment_scriptbeforestartturn", this, c.equipment);
				}
			}
			
			for (c in Deck.drawpile) c.equipment.onetimecheck = false;
			for (c in Deck.drawpile){
				if (!c.equipment.onetimecheck){
					c.equipment.onetimecheck = true;
					Script.rungamescript(c.equipment.scriptbeforestartturn, "equipment_scriptbeforestartturn", this, c.equipment);
				}
			}
		}else{
			for (e in equipment) e.onetimecheck = false;
			for (e in equipment){
				if (!e.onetimecheck){
					e.onetimecheck = true;
					Script.rungamescript(e.scriptbeforestartturn, "equipment_scriptbeforestartturn", this, e);
				}
			}
		}
		
		//Status effects beforestartturn scripts
		for (i in 0 ... status.length){
			if (status[i].value > 0) status[i].runscript("beforestartturn", 0);
		}
	}
	
	public function runonstartturnscripts(){
		Script.rungamescript(scriptonstartturn, "fighter_scriptonstartturn", this);
		
		if (Rules.extrascript_onstartturn.length > 0){
			if(Game.player == this){
				for (i in 0 ... Rules.extrascript_onstartturn.length){
					Script.rungamescript(Rules.extrascript_onstartturn[i], "fighter_scriptonstartturn", this);
				}
			}
		}
		
		if (layout == EquipmentLayout.DECK){
			for (c in Deck.discardpile) c.equipment.onetimecheck = false;
			for (c in Deck.discardpile){
				if (!c.equipment.onetimecheck){
					c.equipment.onetimecheck = true;
					Script.rungamescript(c.equipment.scriptonstartturn, "equipment_scriptbeforestartturn", this, c.equipment);
				}
			}
			for (c in Deck.inplaypile) c.equipment.onetimecheck = false;
			for(c in Deck.inplaypile){
				if (!c.equipment.onetimecheck){
					c.equipment.onetimecheck = true;
					Script.rungamescript(c.equipment.scriptonstartturn, "equipment_scriptbeforestartturn", this, c.equipment);
				}
			}
			for (c in Deck.drawpile) c.equipment.onetimecheck = false;
			for(c in Deck.drawpile){
				if (!c.equipment.onetimecheck){
					c.equipment.onetimecheck = true;
					Script.rungamescript(c.equipment.scriptonstartturn, "equipment_scriptbeforestartturn", this, c.equipment);
				}
			}
		}else{
			for (e in equipment) e.onetimecheck = false;
			for (e in equipment){
				if (!e.onetimecheck){
					e.onetimecheck = true;
					Script.rungamescript(e.scriptonstartturn, "equipment_scriptonstartturn", this, e);
				}
			}
		}
		
		//Status effects onstartturn scripts
		for (i in 0 ... status.length){
			if (status[i].value > 0) status[i].runscript("onstartturn", 0);
		}
	}
	
	public function hasusabledice() : Bool{
		// Special-case code. Locked equipment cannot use dice, but it can request them...
		if (ControlMode.gamepad() && Combat.gamepad_selectedequipment != null) {
			if (Combat.gamepad_selectedequipment.iscurrentlylocked()) {
				return false;
			}
		}
		
		for (d in dicepool) {
			if (d.available()) {
				return true;
			}
		}

		return false;
	}
	
	public function hasrequestdice() : Bool{
		var skillcard:Equipment = getskillcard();
		if (skillcard != null && skillcard.skillcard == "robot_request" && Std.is(skillcard.equipmentpanel, RobotRequestPanel)) {
			var requestpanel:RobotRequestPanel = cast(skillcard.equipmentpanel, RobotRequestPanel);
			
			return requestpanel.hasusabledice();
		}
		
		return false;
	}

	public function createsparedice(e:Equipment){
		//Create dice for SpareDice equipment
		if (e.ready){
			if (e.slots.length > 0){
				for (i in 0 ... e.slots.length){
					if (Game.diceslotissparedice(e.slots[i])){
						if(e.assigneddice[i] == null){
							var newdice:Dice = new Dice();
							newdice.basevalue = Game.diceslotissparedice_getnum(e.slots[i]);
							newdice.assignedposition = i;
							newdice.highlight = 0;
							newdice.x = e.x + e.slotpositions[i].x + Game.dicexoffset;
							newdice.y = e.y + e.slotpositions[i].y + Game.diceyoffset;
							newdice.inlerp = false;
							newdice.assigned = e;
							newdice.owner = this;
							e.assigneddice[i] = newdice;
							
							dicepool.push(newdice);
						}
					}
				}
			}
		}
	}
	
	public function applyequipmentcurses():Bool{
		var returnval:Bool = false;
		
		//Kludge for Polarity Flip + Pandemonium combo in Halloween special
		if (hasstatus("errorall")){
			removestatus("errorall");
			Game.roboterror(this);
			return true;
		}
		
		//Zero out our equipment status plans
		for (i in 0 ... equipment.length){
			equipment[i].applyequipmentstatus = "";
		}
		
		if (hasstatus(Status.ALTERNATE + Status.POISON)) {
			var poisonlist:Array<Equipment> = [];
			for (i in 0 ... equipment.length){
				if (equipment[i].skillcard != ""){
				}else if (equipment[i].onceperbattle && equipment[i].usedthisbattle){
				}else if (!equipment[i].availablethisturn){
				}else if (equipment[i].currentlyreducingcountdown()){
				}else if (equipment[i].containsadicealready()){
				}else if (equipment[i].hastag("altpoisonavoid")){
				}else if (equipment[i].applyequipmentstatus == ""){
					poisonlist.push(equipment[i]);
				}
			}
			
			Random.shuffle(poisonlist);
			
			var randequipment:Equipment = poisonlist.pop();
			if (randequipment != null) {
				if (randequipment.hastag("altpoisonimmune")){
					randequipment.applyequipmentstatus = "altpoisonimmune";
				}else{
					randequipment.applyequipmentstatus = Status.ALTERNATE + Status.POISON;
				}
			}
			
			returnval = true;
		}
		
		if (hasstatus(Status.SHOCK)) {
			var shocklist:Array<Equipment> = [];
			for (i in 0 ... equipment.length){
				if (equipment[i].skillcard != ""){
				}else if (equipment[i].onceperbattle && equipment[i].usedthisbattle){
				}else if (!equipment[i].availablethisturn){
				}else if (equipment[i].shockedsetting >= 1){
				}else if (equipment[i].currentlyreducingcountdown()){
				}else if (equipment[i].containsadicealready()){
				}else if (equipment[i].hastag("shockavoid")){
				}else if (!equipment[i].ready){
				}else if (equipment[i].applyequipmentstatus == ""){
					shocklist.push(equipment[i]);
				}
			}
			
			Random.shuffle(shocklist);
			
			var shock:StatusEffect = getstatus(Status.SHOCK);
			while (shock.value > 0 && shocklist.length > 0){
				var randequipment:Equipment = shocklist.pop();
				if (randequipment.hastag("shockimmune")){
					randequipment.applyequipmentstatus = "shockimmune";
				}else{
					randequipment.applyequipmentstatus = Status.SHOCK;
				}
				shock.value--;
			}
			
			returnval = true;
		}
		
		if (hasstatus(Status.ALTERNATE_SHOCK)) {
			var shocklist:Array<Equipment> = [];
			for (i in 0 ... equipment.length){
				if (equipment[i].skillcard != ""){
				}else if (equipment[i].onceperbattle && equipment[i].usedthisbattle){
				}else if (!equipment[i].availablethisturn){
				}else if (equipment[i].shockedsetting >= 1){
				}else if (equipment[i].currentlyreducingcountdown()){
				}else if (equipment[i].containsadicealready()){
				}else if (equipment[i].hastag("shockavoid")){
				}else if (!equipment[i].ready){
				}else if (equipment[i].applyequipmentstatus == ""){
					shocklist.push(equipment[i]);
				}
			}
			
			Random.shuffle(shocklist);
			
			var alternateshock:StatusEffect = getstatus(Status.ALTERNATE + Status.SHOCK);
			while (alternateshock.value > 0 && shocklist.length > 0){
				var randequipment:Equipment = shocklist.pop();
				if (randequipment.hastag("shockimmune")){
					randequipment.applyequipmentstatus = "shockimmune";
				}else{
					randequipment.applyequipmentstatus = Status.ALTERNATE_SHOCK;
				}
				alternateshock.value--;
			}
			
			returnval = true;
		}
		
		//For weaken, we try two phases. In phase two, we also consider equipment that
		//may already have shock or alternate poison
		for(j in 0 ... 2){
			if (hasstatus(Status.WEAKEN)) {
				var weakenlist:Array<Equipment> = [];
				for (i in 0 ... equipment.length){
					if (equipment[i].skillcard != ""){
					}else if (equipment[i].onceperbattle && equipment[i].usedthisbattle){
					}else if (!equipment[i].availablethisturn){
					}else if (!equipment[i].ready){
					}else if (equipment[i].shockedsetting >= 1){
					}else if (equipment[i].currentlyreducingcountdown()){
					}else if (equipment[i].containsadicealready()){
					}else if (equipment[i].weakened){
					}else if (equipment[i].hastag("weakenavoid")){
					}else if (equipment[i].applyequipmentstatus == "" || j == 1){
						weakenlist.push(equipment[i]);
					}
				}
				
				Random.shuffle(weakenlist);
				
				var weaken:StatusEffect = getstatus(Status.WEAKEN);
				while (weaken.value > 0 && weakenlist.length > 0){
					var randequipment:Equipment = weakenlist.pop();
					if (randequipment.applyequipmentstatus == Status.SHOCK){
						randequipment.applyequipmentstatus = "shock_and_weaken";
					}else if (randequipment.applyequipmentstatus == Status.ALTERNATE_SHOCK){
						randequipment.applyequipmentstatus = "altshock_and_weaken";
					}else if (randequipment.applyequipmentstatus == Status.ALTERNATE_POISON){
						randequipment.applyequipmentstatus = "altpoison_and_weaken";
					}else{
						if (randequipment.hastag("weakenimmune")){
							randequipment.applyequipmentstatus = "weakenimmune";
						}else{
							randequipment.applyequipmentstatus = Status.WEAKEN;
						}
					}
					weaken.value--;
				}
				
				returnval = true;
			}
		}
		
		//Actually apply the animations
		if (returnval){
			var shockcount:Int = 0;
			var weakencount:Int = 0;
			for (i in 0 ... equipment.length){
				if (equipment[i].applyequipmentstatus != ""){
					switch(equipment[i].applyequipmentstatus){
						case Status.SHOCK, "alternate_shock":
							equipment[i].animate(equipment[i].applyequipmentstatus, 0, (shockcount == 0));
							shockcount++;
						case Status.WEAKEN:
							equipment[i].animate(equipment[i].applyequipmentstatus, 0, (weakencount == 0));
							weakencount++;
						default:
							equipment[i].animate(equipment[i].applyequipmentstatus);
					}
				}
				equipment[i].applyequipmentstatus = "";
			}
		}
		
		if (hasstatus(Status.SILENCE)){
			var skillcard:Equipment = getskillcard();
			if(skillcard != null){
				getskillcard().animate("silence");
				returnval = true;
			}
		}
		
		return returnval;
	}
	
	public function getequipmentposition(leavespaceforbuttons:Bool = false){
		//startturn() above moves all equipment off to the side of the screen to start
		var equipmentslots:Array<Array<Int>> = Data.create2darray(4, 2, -1);
		
		for (i in 0 ... equipment.length){
			//initial pos is where the panel exists offscreen. We'll figure out the y value later
			equipment[i].initialpos = new Point(equipment[i].x, 0);
			//final pos is where the panel sits once it's placed. We don't know it yet.
			equipment[i].finalpos = new Point(0, 0);
			equipment[i].row = -1;
			equipment[i].column = -1;
		}
		
		// On the player's board, we'll start by pulling in positions from the inventory.
		if (!Rules.monstermode) {
			if (this == Game.player) {
				for (j in 0 ... Inventory.equipmentslots.height){
					for (i in 0 ... Inventory.equipmentslots.width){
						var collectible:Collectible = Inventory.equipmentslots.contents[i][j];
						if (collectible != null){
							// Find the corresponding equipment on our board.
							var realequipment:Equipment = null;
							for (k in 0 ... equipment.length) {
								if (equipment[k].ready && equipment[k].row == -1 && equipment[k].name == collectible.equipment.name && equipment[k].namemodifier == collectible.equipment.namemodifier) {
									realequipment = equipment[k];
									break;
								}
							}
							if (realequipment == null) {
								if(collectible.equipment != null){
									trace("Equipment \"" + collectible.equipment.name + collectible.equipment.namemodifier + "\" exists in player's inventory, but not in thier equipment array?");
									trace("Inventory: " + Inventory.equipmentslots);
								}
							} else {
								if (realequipment.ready) {
									realequipment.row = j;
									realequipment.column = i;
									equipmentslots[i][j] = 1;
									if (realequipment.size == 4) {
										equipmentslots[i+1][j] = 1;
										equipmentslots[i][j+1] = 1;
										equipmentslots[i+1][j+1] = 1;
									} else if (realequipment.size == 3) {
										equipmentslots[i+1][j] = 1;
									} else if (realequipment.size == 2) {
										equipmentslots[i][j+1] = 1;
									}
								}
							}
						}
					}
				}
			
				// Now check and condense.
				for (i in 0 ... 4) {
					// If there's an empty column, shift everything left.
					if (i < 3) {
						var columnshifts:Int = 0;
						while ((equipmentslots[i][0] == -1 || equipmentslots[i+1][0] == -1) && (equipmentslots[i][1] == -1 || equipmentslots[i+1][1] == -1)) {
							// Empty column.
							for (e in equipment) {
								if (e.column > i) {
									e.column -= 1;
								}
							}

							if (equipmentslots[i][0] == -1) {
								equipmentslots[i][0] = equipmentslots[i + 1][0];
								equipmentslots[i + 1][0] = -1;
							}
							if (equipmentslots[i][1] == -1) {
								equipmentslots[i][1] = equipmentslots[i + 1][1];
								equipmentslots[i + 1][1] = -1;
							}
							
							for (k in i + 1 ... 3) {
								equipmentslots[k][0] = equipmentslots[k + 1][0];
								equipmentslots[k][1] = equipmentslots[k + 1][1];
							}
							
							equipmentslots[3][0] = -1;
							equipmentslots[3][1] = -1;
							
							++columnshifts;
							
							if (columnshifts > 4) {
								break;
							}
						}
					}
					
					// If there's an empty cell at the top of a column, move things up.
					if (equipmentslots[i][0] == -1 && equipmentslots[i][1] != -1) {
						for (e in equipment) {
							if (e.column == i && e.row == 1) {
								e.row = 0;
							}
						}
						equipmentslots[i][0] = 1;
						equipmentslots[i][1] = -1;
					}
				}
			}
		}
		
		// Fill in other equipment. This organises monster equipment and covers additional equipment such as skill cards.
		for (e in equipment){
			if(e.ready && e.row == -1){
				if (e.size == 4){
					//Comically oversized equipment
					for (i in 0 ... 3){
						if (equipmentslots[i][0] == -1 && equipmentslots[i + 1][0] == -1 &&
								equipmentslots[i][1] == -1 && equipmentslots[i + 1][1] == -1){
							e.row = 0; e.column = i;
							equipmentslots[i][0] = 1;
							equipmentslots[i + 1][0] = 1;
							equipmentslots[i][1] = 1;
							equipmentslots[i + 1][1] = 1;
							break;
						}
					}
				}else if (e.size == 3){
					//Two horizontal slots
					for (i in 0 ... 3){
						for (j in 0 ... 2){
							if (equipmentslots[i][j] == -1 && equipmentslots[i + 1][j] == -1){
								e.row = j; e.column = i;
								equipmentslots[i][j] = 1;
								equipmentslots[i + 1][j] = 1;
								break;
							}
						}
					}
				}else if (e.size == 2){
					//Two vertical slots
					for (i in 0 ... 4){
						if (equipmentslots[i][0] == -1 && equipmentslots[i][1] == -1){
							e.row = 0; e.column = i;
							equipmentslots[i][0] = 1;
							equipmentslots[i][1] = 1;
							break;
						}
					}
				}else if (e.size == 1){
					//Any free slot! Prioritise the bottom half of two vertical slots if the top half is full
					for (i in 0 ... 4){
						if (equipmentslots[i][0] == -1){
							e.row = 0; e.column = i;
							equipmentslots[i][0] = 1;
							break;
						}else if(equipmentslots[i][1] == -1){
							e.row = 1; e.column = i;
							equipmentslots[i][1] = 1;
							break;
						}
					}
				}
			}
		}
		
		//Ok! We have a row and column for all of our equipment. Let's figure out some bounds:
		var equipwidth:Int = -1;
		var equipheight:Int = -1;
		for (i in 0 ... 4){
			for (j in 0 ... 2){
				if (equipmentslots[i][j] == 1){
					if (i > equipwidth) equipwidth = i;
					if (i > equipheight) equipheight = j;
				}
			}
		}
		equipwidth++;
		equipheight++;
		
		//We use this to get initial y positions:
		for (e in equipment){
			if(e.ready){
				if (e.skillcard != ""){
					e.y = e.initialpos.y = Screen.heightmid - (e.height / 2);
				}
				if (e.size == 2 || e.size == 4){
					e.y = e.initialpos.y = Screen.heightmid - (e.height / 2);
					if (leavespaceforbuttons) {
						e.y -= Std.int(ExtendedGui.buttonheight * 0.6);
						e.initialpos.y -= Std.int(ExtendedGui.buttonheight * 0.6);
					}
				}else{
					if (e.row == 0){
						if (e.size == 1 && equipmentslots[e.column][1] == -1){
							e.y = e.initialpos.y = Screen.heightmid - (e.height / 2);
							if (leavespaceforbuttons) {
								e.y -= Std.int(ExtendedGui.buttonheight * 0.6);
								e.initialpos.y -= Std.int(ExtendedGui.buttonheight * 0.6);
							}
						}else{
							e.y = e.initialpos.y = Screen.heightmid - e.height - 2;
							if (leavespaceforbuttons) {
								e.y -= Std.int(ExtendedGui.buttonheight * 1.5);
								e.initialpos.y -= Std.int(ExtendedGui.buttonheight * 1.5);
							}
						}
					}else{
						if (e.size == 1 && equipmentslots[e.column][0] == -1){
							e.y = e.initialpos.y = Screen.heightmid - (e.height / 2);
							if (leavespaceforbuttons) {
								e.y -= Std.int(ExtendedGui.buttonheight * 0.6);
								e.initialpos.y -= Std.int(ExtendedGui.buttonheight * 0.6);
							}
						}else{
							e.y = e.initialpos.y = Screen.heightmid + 2;
							if (leavespaceforbuttons) {
								e.y += Std.int(ExtendedGui.buttonheight * 0.2);
								e.initialpos.y += Std.int(ExtendedGui.buttonheight * 0.2);
							}
						}
					}
				}
			}
			
			//Final y positions match the initial ones (we tween in from the sides of the screen)
			e.finalpos.y = e.initialpos.y;
		}
		
		//Finally, we figure out the x positions and confirm rows/columns
		var xoffset:Float = Screen.widthmid - ((equipwidth * 160 * 6) / 2) + (((160 - 140) * 6) / 2);
		for (i in 0 ... equipment.length) {
			var j:Int = (equipment.length - i) - 1;
			equipment[j].finalpos.x = xoffset + ((equipment[j].column * 160 * 6));
			equipment[j].displayrow = equipment[j].row;
			equipment[j].displaycolumn = equipment[j].column;
		}
		
		equipmentslotsleft = 0;
		for (i in 0 ... 4){
			for (j in 0 ... 2){
			  if (equipmentslots[i][j] == -1) equipmentslotsleft++;	
			}
		}
	}
	
	/* Used for things like copycat. Just ditch everything we currently have equipped. */
	public function destroyallequipment(){
		for (e in equipment){
			e.dispose();
		}
		
		equipment = [];
	}
	
	/* Get an array of currently equipped things that sensitive to layout. Used for Copycat, basically. */
	public function getcurrentequipment():Array<Equipment>{
		var returnlist:Array<Equipment> = [];
		var i:Int = 0;
		
		if (layout == EquipmentLayout.EQUIPMENT){
			for (i in 0 ... equipment.length){
				if(equipment[i].skillcard == ""){
					returnlist.push(equipment[i]);
				}
			}
		}else if (layout == EquipmentLayout.DECK){
			//For the deck, we wanna get the list of equipment in *any* order. Since this is just
			//used for Copycat right now, stop at three.
			for (c in Deck.inplaypile){
				if (c.equipment.skillcard == ""){
					returnlist.push(c.equipment);
				}
			}
			for (c in Deck.discardpile){
				if (c.equipment.skillcard == ""){
					returnlist.push(c.equipment);
				}
			}
			for (c in Deck.drawpile){
				if (c.equipment.skillcard == ""){
					returnlist.push(c.equipment);
				}
			}
			returnlist = Random.shuffle(returnlist);
			while (returnlist.length > 3) returnlist.pop();
		}else if (layout == EquipmentLayout.SPELLBOOK){
			for (i in 0 ... Spellbook.equipmentslots.length) {
				if (Spellbook.equipmentslots[i] != null){
					if(equipment[i].skillcard == ""){
						returnlist.push(equipment[i]);
					}
				}
			}
		}
		return returnlist;
	}
	
	public function fetchequipment(position:String, delay:Float = 0.25){
		if (Rules.monstermode){
		  if (Monstermode.mode == "selection"){
				//Handled elsewhere! Make sure we don't make any noise or do any animations here.
				Game.equipmentplaced = Monstermode.cardlist.length;
			  Game.equipmenttoplace = Game.equipmentplaced;
				
				getequipmentposition();
				
				AudioControl.play("cardappear");
				for(i in 0 ... equipment.length){
					equipment[i].equippedby = this;
					var j:Int = (equipment.length - i) - 1;
					if (position == "left"){
						equipment[j].x = equipment[j].finalpos.x - Screen.width;
						equipment[j].y = equipment[j].finalpos.y;
					}else if (position == "right"){
						equipment[j].x = equipment[j].finalpos.x + Screen.width;
						equipment[j].y = equipment[j].finalpos.y;
					}else if (position == "top" || position == "finderskeepers"){
						equipment[j].x = equipment[j].finalpos.x;
						equipment[j].y = equipment[j].finalpos.y - Screen.height;
					}else if (position == "bottom"){
						equipment[j].x = equipment[j].finalpos.x;
						equipment[j].y = equipment[j].finalpos.y + Screen.height;
					}
					
					if (equipment[j].ready){
						equipment[j].x = equipment[j].finalpos.x;
						equipment[j].y = equipment[j].finalpos.y;
					}
				}
				
				return;
			}
		}
		
		if (Rules.inventor_equipmentrust > 0){
			//Rust only applies to player equipment
			if (Game.player != this){
				for (i in 0 ... equipment.length){
					equipment[i].totalusesremaining = 0;
				}
			}
		}
		
		if (layout == EquipmentLayout.EQUIPMENT){
			if (position == "finderskeepers"){
				getequipmentposition(true);
			}else{
				getequipmentposition();
			}
			
			Game.equipmentplaced = 0;
			Game.equipmenttoplace = equipment.length;
			
			if (Combat.isconfused){
				//Mix up the equipment positions!
				var size1equipment:Array<Equipment> = [];
				var size1equipmentscrambled:Array<Equipment> = [];
				var size1equipmentposition:Array<Point> = [];
				var size2equipment:Array<Equipment> = [];
				var size2equipmentscrambled:Array<Equipment> = [];
				var size2equipmentposition:Array<Point> = [];
				
				for (i in 0 ... equipment.length){
					if (!equipment[i].skillcard_special){
						if (equipment[i].size == 1){
							size1equipment.push(equipment[i]);
							size1equipmentscrambled.push(equipment[i]);
						}else if (equipment[i].size == 2){
							size2equipment.push(equipment[i]);
							size2equipmentscrambled.push(equipment[i]);
							size2equipmentposition.push(equipment[i].finalpos.clone());
						}
					}
				}

				size1equipmentscrambled = Random.shuffle(size1equipmentscrambled);
				size2equipmentscrambled = Random.shuffle(size2equipmentscrambled);
				
				for (i in 0 ... size1equipment.length){
					size1equipmentposition[i] = size1equipmentscrambled[i].finalpos.clone();
				}
				for (i in 0 ... size2equipment.length){
					size2equipmentposition[i] = size2equipmentscrambled[i].finalpos.clone();
				}
				
				for (i in 0 ... size1equipment.length){
					size1equipment[i].finalpos = size1equipmentposition[i];
					size1equipment[i].displayrow = size1equipmentscrambled[i].row;
					size1equipment[i].displaycolumn = size1equipmentscrambled[i].column;
				}
				for (i in 0 ... size2equipment.length){
					size2equipment[i].finalpos = size2equipmentposition[i];
					size2equipment[i].displayrow = size2equipmentscrambled[i].row;
					size2equipment[i].displaycolumn = size2equipmentscrambled[i].column;
				}
			} else {
				for (i in 0 ... equipment.length){
					equipment[i].displayrow = equipment[i].row;
					equipment[i].displaycolumn = equipment[i].column;
				}
			}
			
			for(i in 0 ... equipment.length){
				equipment[i].equippedby = this;
				var j:Int = (equipment.length - i) - 1;
				if (position == "left"){
					equipment[j].x = equipment[j].finalpos.x - Screen.width;
					equipment[j].y = equipment[j].finalpos.y;
				}else if (position == "right"){
					equipment[j].x = equipment[j].finalpos.x + Screen.width;
					equipment[j].y = equipment[j].finalpos.y;
				}else if (position == "top" || position == "finderskeepers"){
					equipment[j].x = equipment[j].finalpos.x;
					equipment[j].y = equipment[j].finalpos.y - Screen.height;
				}else if (position == "bottom"){
					equipment[j].x = equipment[j].finalpos.x;
					equipment[j].y = equipment[j].finalpos.y + Screen.height;
				}
				
				if (equipment[j].ready){
					Game.delaycall(function(){
							AudioControl.play("cardappear");
					}, i * delay / BuildConfig.speed);
					Actuate.tween(equipment[j], 0.5 / (BuildConfig.speed * Settings.animationspeed), { x: equipment[j].finalpos.x , y: equipment[j].finalpos.y })
						.delay(i * delay / BuildConfig.speed)
						.onComplete(function(){
							Game.equipmentplaced++;
						});
				}else{
					Game.equipmenttoplace--;
				}
			}
		}else if (layout == EquipmentLayout.SPELLBOOK){
			//Witch has a special fixed layout
			//Spell book is always on the right hand side
			//See also: Spellbook.summon_create, where new equipment is positioned when summoned
			var xoffset:Float = Spellbook.xoffset;
			var skillcard:Equipment = getskillcard();
			skillcard.initialpos = new Point(0, 0);
			skillcard.finalpos = new Point(0, 0);
			skillcard.finalpos.x = xoffset + 280 * 6;
			skillcard.finalpos.y = Screen.heightmid - Std.int(skillcard.height / 2);
			skillcard.x = skillcard.initialpos.x = skillcard.finalpos.x + Screen.width;
			skillcard.y = skillcard.initialpos.y = skillcard.finalpos.y;
			skillcard.displayrow = skillcard.row = 0;
			skillcard.displaycolumn = skillcard.column = 2;
			
			Spellbook.slotpositionoffset.x = -Screen.width;
			Spellbook.slotpositionoffset.y = 0;
			
			Actuate.tween(Spellbook.slotpositionoffset, 0.5 / (BuildConfig.speed * Settings.animationspeed), { x: 0 });
			
			Game.equipmentplaced = 0;
			Game.equipmenttoplace = 1;
			
			Actuate.tween(skillcard, 0.5 / (BuildConfig.speed * Settings.animationspeed), { x: skillcard.finalpos.x , y: skillcard.finalpos.y })
				.onComplete(function(){ Game.equipmentplaced++; });
			
			for (i in 0 ... Spellbook.equipmentslots.length) {
				if (Spellbook.equipmentslots[i] != null){
					Game.equipmenttoplace++;
					Spellbook.equipmentslots[i].initialpos = new Point(0, 0);
					Spellbook.equipmentslots[i].finalpos = new Point(0, 0);
					
					Spellbook.equipmentslots[i].finalpos.x = xoffset + Spellbook.slotposition[i].x;
					Spellbook.equipmentslots[i].finalpos.y = Spellbook.slotposition[i].y;
					
					Spellbook.equipmentslots[i].x = Spellbook.equipmentslots[i].initialpos.x = Spellbook.equipmentslots[i].finalpos.x - Screen.width;
					Spellbook.equipmentslots[i].y = Spellbook.equipmentslots[i].initialpos.y = Spellbook.equipmentslots[i].finalpos.y;
				}
			}
			
			for (i in 0 ... Spellbook.equipmentslots.length){
				if (Spellbook.equipmentslots[i] != null){
					Spellbook.equipmentslots[i].equippedby = this;
					Spellbook.equipmentslots[i].displayrow = Spellbook.equipmentslots[i].row = i >> 1;
					Spellbook.equipmentslots[i].displaycolumn = Spellbook.equipmentslots[i].column = i & 1;
					
					if (Spellbook.equipmentslots[i].ready){
						Game.delaycall(function(){
							AudioControl.play("cardappear");
						}, (i + 1) * 0.25 / BuildConfig.speed);
						Actuate.tween(Spellbook.equipmentslots[i], 0.5 / (BuildConfig.speed * Settings.animationspeed), { x: Spellbook.equipmentslots[i].finalpos.x , y: Spellbook.equipmentslots[i].finalpos.y })
							.delay((i + 1) * 0.25 / BuildConfig.speed)
							.onComplete(function(){
								Game.equipmentplaced++; 
								if (Game.equipmentplaced >= Game.equipmenttoplace){
									if (layout == EquipmentLayout.SPELLBOOK){
										for(i in 0 ... Rules.witch_randomspellslot.length){
											if (Rules.witch_randomspellslot[i].length > 0) Spellbook.sorceresssummon(i, Rules.witch_randomspellslot[i]);
										}
									}
								}
							});
					}else{
						Game.equipmenttoplace--;
					}
				}
			}
			
			var slotsused:Int = 0;
			for (i in 0 ... Spellbook.equipmentslots.length){
				if (Spellbook.equipmentslots[i] != null){
					slotsused++;
				}
			}
			if (slotsused == 0){
				for(i in 0 ... Rules.witch_randomspellslot.length){
					if (Rules.witch_randomspellslot[i].length > 0) Spellbook.sorceresssummon(i, Rules.witch_randomspellslot[i], 0.5 / (BuildConfig.speed * Settings.animationspeed));
				}
			}
			
			if (Combat.turncount == 1){
				//On the first turn, place the casting shadows behind equipment now
				for (i in 0 ... Spellbook.equipmentslots.length){
					if (Spellbook.equipmentslots[i] != null){
						Spellbook.showshadow[i] = true;
					}
				}
			}
			
			if (Spellbook.equipmentslots[0] != null) {
				Combat.gamepad_selectedequipment = Spellbook.equipmentslots[0];
			}
		}else if (layout == EquipmentLayout.DECK){
			//Jester needs to create equipment based on the "play" pile in the deck.
			Deck.resetfornewturn(this);
			Deck.createplaypile(this);
			Deck.rearrangeplaypile(this);
			
			Combat.gamepad_selectedequipment = null;
			for (i in 0 ... equipment.length){
				if (equipment[i].ready) {
					Combat.gamepad_selectedequipment = equipment[i];
					break;
				}
			}
			
			//And the skillcard is done seperately
			
			Deck.skillcard.initialpos = new Point(Screen.width + (10 * 6), Screen.heightmid - (Deck.skillcard.height / 2));
			Deck.skillcard.x = Deck.skillcard.initialpos.x;
			Deck.skillcard.y = Deck.skillcard.initialpos.y;
			var xoffset:Float = Screen.widthmid - ((4 * 160 * 6) / 2) + (((160 - 140) * 6) / 2);
			Deck.skillcard.finalpos = new Point(xoffset + (3 * 160 * 6), Deck.skillcard.initialpos.y);
			Deck.skillcard.displaycolumn = Deck.skillcard.column = 3;
			
			for (i in 0 ... Deck.cardslotoffset.length){
				Deck.cardslotoffset[i] = Screen.width + (10 * 6);
				function changecardoffset(t:Int, v:Float){
					Deck.cardslotoffset[t] = v;
				}
				Actuate.update(changecardoffset, 0.5 / (BuildConfig.speed * Settings.animationspeed), [i, Screen.width + (10 * 6)], [i, 0]);
			}
			
			Actuate.tween(Deck.skillcard, 0.5 / (BuildConfig.speed * Settings.animationspeed), { x: Deck.skillcard.finalpos.x, y: Deck.skillcard.finalpos.y });
				//.delay(3 * 0.25 / BuildConfig.speed);
		}
	}
	
	public var equipmentslotsleft:Int;
	
	public function getdiceposition(position:Int, index:Int):Point {
		var newxpos:Float = 0;
		var newypos:Float = 0;
		
		if (position == Gfx.BOTTOM) {
			var dicecolumns:Int = Math.ceil(((550 * 6 - 1) - Game.playerdicexposition) / (50 * 6));
			
			newxpos = Game.playerdicexposition + (index % dicecolumns) * 50 * 6;
			newypos = Screen.height - Game.playerdiceyposition - Math.floor(index / dicecolumns) * 50 * 6;
		} else {
			var dicecolumns:Int = Math.ceil(((340 * 6 - 1) - (10 * 6)) / (50 * 6));
			
			newxpos = 340 * 6 - (index % dicecolumns) * 50 * 6;
			newypos = 20 * 6 + Math.floor(index / dicecolumns) * 50 * 6;
		}
		
		if (newxpos < 0) newxpos = 0;
		if (newypos < 0) newypos = 0;
		if (newxpos >= Screen.width - 240) newxpos = Screen.width - 240;
		if (newypos >= Screen.height - 240) newypos = Screen.height - 240;
		
		return new Point(newxpos, newypos);
	}
	
	public function findnewdiceposition(position:Int, startidx:Int):Point {
		var dicecollision:Bool = true;
		var placementpoint:Point = null;
		var placementattempt:Int = 0;
		
		while (dicecollision) {
			placementpoint = getdiceposition(position, startidx + placementattempt);
			
			dicecollision = false;
			for (d in dicepool) {
				if (d.availableorlocked()) {
					var dx:Float = d.inlerp ? d.targetx : d.x;
					var dy:Float = d.inlerp ? d.targety : d.y;
					if (Geom.overlap(placementpoint.x, placementpoint.y, 240, 240, dx, dy, 240, 240)) {
						dicecollision = true;
						break;
					}
				}
			}
			
			++placementattempt;

			// HACK we tried but there's not enough space in the grid stacking the new dice on top of another
			if(placementattempt > 42) {
				break;
			}
		}
		
		return placementpoint;
	}
	
	public function rolldice(numdice:Int, position:Int, ?customx:Float = 0, ?customy:Float = 0, ?dicerollsound:String = "diceroll", ?stackdice:Bool = false):Array<Dice>{
		if (Tutorial.prevent_dicerolls) return [];
		
		Game.diceplaced = 0;
		Game.dicetoplace = numdice;
		
		var robotbehavior:Bool = false;
		if (usecpuinsteadofdice){
			robotbehavior = true;
		}
		
		var returnpool:Array<Dice> = [];
		var dicestatdelay:Float = 0.6;
		var alternatefrozentarget:Int = 0;
		var frozentarget:Int = 0;
		var alternateburntarget:Int = 0;
		var burntarget:Int = 0;
		
		if (!robotbehavior){
			if (hasstatus(Status.ICE)){
				var frozenstat:StatusEffect = getstatus(Status.ICE);
				frozentarget = frozenstat.value;
			}
			
			if (hasstatus(Status.ALTERNATE + Status.ICE)){
				var alternatefrozenstat:StatusEffect = getstatus(Status.ALTERNATE + Status.ICE);
				alternatefrozentarget = alternatefrozenstat.value;
			}
			
			if (hasstatus(Status.FIRE)){
				var burnstat:StatusEffect = getstatus(Status.FIRE);
				burntarget = burnstat.value;
			}
			
			if (hasstatus(Status.ALTERNATE + Status.FIRE)){
				var alternateburnstat:StatusEffect = getstatus(Status.ALTERNATE + Status.FIRE);
				alternateburntarget = alternateburnstat.value;
			}
		}
		
		var blindtarget:Int = 0;
		var blindeddice:Int = 0;
		if (hasstatus(Status.BLIND)){
			var blindstat:StatusEffect = getstatus(Status.BLIND);
			blindtarget = blindstat.value;
			blindeddice = blindtarget;
			
			if (robotbehavior){
				if (!hasstatus("robotblinded")){
					addstatus("robotblinded", 1);
				}
			}
		}
		
		var alternateconfusedactive:Bool = false;
		if (hasstatus(Status.ALTERNATE + Status.CONFUSE)){
			alternateconfusedactive = true;
		}
		
		var locktarget:Int = 0;
		var lockeddice:Int = 0;
		if (hasstatus(Status.LOCK)){
			var lockstat:StatusEffect = getstatus(Status.LOCK);
			locktarget = lockstat.value;
			lockeddice = locktarget;
		}
		
		var alternatelocktarget:Int = 0;
		var alternatelockeddice:Int = 0;
		if (!robotbehavior){
			if (hasstatus(Status.ALTERNATE_LOCK)){
				var alternatelockstat:StatusEffect = getstatus(Status.ALTERNATE_LOCK);
				alternatelocktarget = alternatelockstat.value;
				alternatelockeddice = alternatelocktarget;
				alternatelockstat.value = 0;
			}
		}
		
		for (i in 0 ... numdice){
			var newdice:Dice;
			newdice = new Dice(Screen.width, Screen.height);
			newdice.owner = this;
			
			if (blindtarget > 0){
				newdice.blind = true;
				blindtarget--;
			}
			
			if (alternateconfusedactive){
				newdice.blind = true;
			}
			
			if (locktarget > 0){
				newdice.animate(Status.LOCK, dicestatdelay);
				locktarget--;
				dicestatdelay += 0.25;
			}
			
			if (alternatelocktarget > 0){
				//newdice.animate(Status.ALTERNATE_LOCK, dicestatdelay);
				newdice.priority = true;
				alternatelocktarget--;
				dicestatdelay += 0.25;
			}
			
			if (alternateburntarget > 0){
				newdice.animate(Status.ALTERNATE + Status.FIRE, dicestatdelay);
				alternateburntarget--;
				dicestatdelay += 0.25;
			}
			
			if (burntarget > 0){
				newdice.animate(Status.FIRE, dicestatdelay);
				burntarget--;
				dicestatdelay += 0.25;
			}
			
			var placementpoint:Point = findnewdiceposition(position, i);
			var newxpos:Float = placementpoint.x;
			var newypos:Float = placementpoint.y;
			
			newdice.x = newxpos;
			if (position == Gfx.BOTTOM) {
				newdice.y = Screen.height + 5 * 6;
			} else {
				newdice.y = -45 * 6;
			}
			
			if (customx != 0){
				newdice.x = customx;
				newdice.y = customy;
				
				newdice.inlerp = true;
				Actuate.tween(newdice, 0.5 / BuildConfig.speed, {x: newxpos, y: newypos})
					.delay(0.2 * i / BuildConfig.speed)
					.onComplete(function(d:Dice){
						d.inlerp = false;
						Game.diceplaced++;
					}, [newdice]);
			}else{
				newdice.inlerp = true;
				Actuate.tween(newdice, 0.5 / BuildConfig.speed, {y: newypos})
					.delay(0.2 * i / BuildConfig.speed)
					.onComplete(function(d:Dice){
						d.inlerp = false;
						Game.diceplaced++;
					}, [newdice]
					);
			}
			
			newdice.roll(this);
			
			returnpool.push(newdice);
			dicepool.push(newdice);
			
			if (i == 0 && this == Game.player) {
				if (!Combat.gamepad_dicemode) {
					Combat.gamepaddicetrail_prevdice = Combat.gamepad_selecteddice;
					Combat.gamepad_selecteddice = newdice;
				}
			}
			
			newdice.targetx = newxpos;
			newdice.targety = newypos;
		}
		
		AudioControl.play(dicerollsound);
		
		if (frozentarget > 0){
			dicestatdelay += 0.2 * (dicepool.length / BuildConfig.speed);
			//Slightly kludgy: if a dice has an animation, right now, that means we know
			//it's burning. This may not always be true, and could cause problems later.
			//Hi future Terry!
			var nexthighestdice:Dice = Game.gethighestunfrozendice(dicepool);
			while(frozentarget > 0 && nexthighestdice != null){
				//Get the highest, unfrozen dice in the returnpool
				nexthighestdice.frozen = true;
				nexthighestdice.animate(Status.ICE, dicestatdelay);
				
				//Immediately reduce the frozen status (prevents status effect getting applied twice later)
				var stat:StatusEffect = getstatus(Status.ICE);
				stat.value--;
				
				frozentarget--;
				dicestatdelay += 0.25;
			  nexthighestdice = Game.gethighestunfrozendice(dicepool);
			}
		}
		
		if (alternatefrozentarget > 0){
			//Slightly kludgy: if a dice has an animation, right now, that means we know
			//it's burning. This may not always be true, and could cause problems later.
			//Hi future Terry!
			dicestatdelay += 0.2 / BuildConfig.speed;
			
			for (i in 0 ... dicepool.length){
				if (dicepool[i].animation.length == 0){
					dicepool[i].frozen = true;
				}
			}
			
			for (j in 0 ... alternatefrozentarget){
				Game.delaycall(function(){
					AudioControl.play("_dicefreeze");
					for (i in 0 ... dicepool.length){
						if (dicepool[i].frozen){
							dicepool[i].animate(Status.ALTERNATE + Status.ICE);
						}
					}
				}, dicestatdelay);
				dicestatdelay += 0.15 / BuildConfig.speed;
			}
			
			Game.delaycall(function(){
				for (i in 0 ... dicepool.length){
					dicepool[i].frozen = false;
				}
			}, dicestatdelay);
			alternatefrozentarget = 0;
		}
		
		for (j in 1 ... 7){
			if (hasstatus("counter_" + j)){
				for (i in 0 ... dicepool.length){
					if(dicepool[i].basevalue == j){
						dicepool[i].locked = true;
					}
				}
			}
			
			if (hasstatus("alternate_counter_" + j)){
				var numpriority:Int = 0;
				for (i in 0 ... dicepool.length){
					if (dicepool[i].basevalue == j){
						//dicepool[i].animate(Status.ALTERNATE_LOCK, 0.5 / BuildConfig.speed);
						dicepool[i].priority = true;
						numpriority++;
					}
				}
				//This basically just applies a "lock" status effect that's already spent
				if (numpriority > 0){
					addstatus(Status.ALTERNATE_LOCK, numpriority);
					// if fighter is immune to lock it will crash, check that the lock status has been applied
					if(hasstatus(Status.ALTERNATE_LOCK)) {
						getstatus(Status.ALTERNATE_LOCK).value -= numpriority;
					}
				}
			}
			
			if(Game.monster == this){
				if (Game.player.hasstatus("dice_trigger_" + j)){
					for (i in 0 ... dicepool.length){
						if (dicepool[i].basevalue == j){
							Game.player.bonusdice++;
							Screen.shake();
						}
					}
				}
				
				if (Game.player.hasstatus("alternate_dice_trigger_" + j)){
					for (i in 0 ... dicepool.length){
						if (dicepool[i].basevalue == j){
							Game.player.addstatus("stash" + j, 1);
						}
					}
				}
			}
		}
		
		if (!robotbehavior){
			if (blindeddice > 0){
				if (hasstatus(Status.BLIND)){
					var blindstat:StatusEffect = getstatus(Status.BLIND);
					blindstat.value = 0;
				}
			}
			
			if (alternateburntarget > 0){
				if (hasstatus(Status.ALTERNATE + Status.FIRE)){
					var alternateburnstat:StatusEffect = getstatus(Status.ALTERNATE + Status.FIRE);
					alternateburnstat.value -= alternateburntarget;
				}
			}
			
			if (burntarget > 0){
				if (hasstatus(Status.FIRE)){
					var burnstat:StatusEffect = getstatus(Status.FIRE);
					burnstat.value -= burntarget;
				}
			}
		} else {
			if (blindeddice > 0){
				if (hasstatus(Status.BLIND)){
					var blindstat:StatusEffect = getstatus(Status.BLIND);
					blindstat.value -= numdice;
				}
			}
			
			//We don't reduce the lock stat in the animation any more
			if (lockeddice > 0){
				if (hasstatus(Status.LOCK)){
					var lockstat:StatusEffect = getstatus(Status.LOCK);
					lockstat.value -= numdice;
				}
			}
			
			if (!robotbehavior){
				if (alternatelockeddice > 0){
					if (hasstatus(Status.ALTERNATE_LOCK)){
						var alternatelockstat:StatusEffect = getstatus(Status.ALTERNATE_LOCK);
						alternatelockstat.value -= numdice;
					}
				}
			}
		}
		
		if (stackdice){
			if(BuildConfig.debug_testdiceroll){
				for (i in 0 ... returnpool.length){
					returnpool[i].basevalue = BuildConfig.debug_testdicerolldice[i % BuildConfig.debug_testdicerolldice.length];
				}
			}
			
			if (Game.rules_stackenemydice){
				//Stacking rules:
				//_resetsequence and _looponce refers to single sequences of dice, e.g. [[1, 2, 3]]
				//   _looponce means that once we've stacked those dice, we stop stacking dice rolls.
				//   _resetsequence means that at the start of the turn, we start over. Sometimes we don't want this (e.g. Countdown)
				//_loopsequence refers to multiple sequences of dice, and means loop through the 
				//   sequence of stacked rolls, e.g. [[1, 2, 3], [4, 5, 6]]
				if (Combat.turn == "monster"){
					var checkforloopsequenceisok:Bool = true;
					
					if(!Game.rules_stackenemydice_loopsequence){
						if ((Combat.turncount - 1) >= Rules._stackenemydice.length){
							checkforloopsequenceisok = false;
						}
					}
					
					if(checkforloopsequenceisok){
						var stackedpool:Array<Int> = Rules._stackenemydice[(Combat.turncount - 1) % Rules._stackenemydice.length];
						if (Game.rules_stackenemydice_looponce){
							for (i in 0 ... returnpool.length){
								if (Game.rules_stackenemydice_index < stackedpool.length){
									returnpool[i].basevalue = stackedpool[Game.rules_stackenemydice_index];
									Game.rules_stackenemydice_index++;
								}
							}
						}else{
							for (i in 0 ... returnpool.length){
								returnpool[i].basevalue = stackedpool[Game.rules_stackenemydice_index % stackedpool.length];
								Game.rules_stackenemydice_index++;
							}
						}
					}
				}
			}
			
			if (Game.rules_stackplayerdice){
				if (Combat.turn == "player"){
					var checkforloopsequenceisok:Bool = true;
					
					if(!Game.rules_stackplayerdice_loopsequence){
						if ((Combat.turncount - 1) >= Rules._stackplayerdice.length){
							checkforloopsequenceisok = false;
						}
					}
					
					if(checkforloopsequenceisok){
						var stackedpool:Array<Int> = Rules._stackplayerdice[(Combat.turncount - 1) % Rules._stackplayerdice.length];
						if (Game.rules_stackplayerdice_looponce){
							for (i in 0 ... returnpool.length){
								if (Game.rules_stackplayerdice_index < stackedpool.length){
									returnpool[i].basevalue = stackedpool[Game.rules_stackplayerdice_index];
									Game.rules_stackplayerdice_index++;
								}
							}
						}else{
							for (i in 0 ... returnpool.length){
								returnpool[i].basevalue = stackedpool[Game.rules_stackplayerdice_index % stackedpool.length];
								Game.rules_stackplayerdice_index++;
							}
						}
					}
				}
			}
		}
		
		if (!robotbehavior){
			if (hadstatus(Status.ALTERNATE_LOCK)){
				for (d in dicepool){
					d.locked = true;
				}
			}
			
			Game.updatedicehistory(returnpool);
			ProgressTracking.dicerollchecks();
		}
		
		return returnpool;
	}
	
	//After the initial dice roll phase, we no longer want certain dice statuses to effect future rolls.
	//E.g. If we have two dice and are frozen for three, we don't want a new dice created by a reroll card, say,
	//to be frozen. So, after the initial phase, this function is called to basically extinguish all further
	//dice status effects.
	public function preventfurtherdicestatuseffects(){
		if (!usecpuinsteadofdice){
			if (hasstatus(Status.ICE)){
				var frozenstat:StatusEffect = getstatus(Status.ICE);
				frozenstat.value = 0;
			}
		}
	}
	
	/* Call this script in a future turn. Cannot stack. */
	public function addjinx(jinxvalue:Int, jinxname:String, jinxtooltipdescription:String, jinxcarddescription:String, jinxscript:String, castby:Fighter, turns:Int){
		var jinxtooltipindex:Int = 1;
		for (i in 0 ... status.length){
			if (status[i].jinx){
				var thisjinxvalue:Int = Std.parseInt(S.getbranch(status[i].type, "_"));
				if (thisjinxvalue >= jinxtooltipindex){
					jinxtooltipindex = thisjinxvalue + 1;
				}
			}
		}
			
		if (S.isinstring(jinxname, "%VAR%")){
			jinxname = StringTools.replace(jinxname, "%VAR%", "" + jinxvalue);
		}
		
		if (S.isinstring(jinxscript, "%VAR%")){
			jinxscript = StringTools.replace(jinxscript, "%VAR%", "" + jinxvalue);
		}
		
		var jinx:StatusEffect = new StatusEffect("jinx_" + jinxtooltipindex + "|" + jinxname + "|" + jinxtooltipdescription, turns, this);
		jinx.jinxscript = jinxscript;
		jinx.jinxcarddescription = jinxcarddescription;
		jinx.jinxcastby = castby;
		jinx.jinxvar = jinxvalue;
		jinx.updatedescription();
		status.push(jinx);
		
		if(!jinx.invisible) {
			var tooltipfunc = function() {
				var desc:Array<String> = ["[jinx]_" + Locale.translate(jinx.name) + "[]"];
				for (v in jinx.description) desc.push(Locale.translate(v));
				return desc;
			}
			TooltipManager.addtooltipwithfunc((isplayer?"player":"enemy") + "_" + jinx.type, tooltipfunc, "status", "gamefontsmall", Col.WHITE, Text.LEFT);
		}
	}
	
	public function isjinxed():Bool{
		for (i in 0 ... status.length){
			if (status[i].jinx){
				return true;
			}
		}
		return false;
	}
	
	public function addstatus(stat:String, value:Int){
		var alreadyhas:Bool = false;
		var immune:Bool = false;
		if (Innate.has(this, "immunestatus")){
			if (stat == Status.ICE) immune = true;
			if (stat == Status.ALTERNATE_ICE) immune = true;
			if (stat == Status.LOCK) immune = true;
			if (stat == Status.ALTERNATE_LOCK) immune = true;
			// counter and alternate_counter are also immune
			if (stat.indexOf('counter_') > -1) immune = true;
		}
		
		if (Innate.has(this, "immunefreeze")){
			if (stat == Status.ICE) immune = true;
			if (stat == Status.ALTERNATE_ICE) immune = true;
		}
		
		if (!immune){
			if (Rules.overload) value = value * 2;
			
			if (Rules.hasalternate(stat)) stat = Status.ALTERNATE + stat;
			
			if (stat == Status.ALTERNATE_SURVIVE){
				//Special: Alt survive gets added 3 at a time, and cannot exceed 3
				if (hasstatus(Status.ALTERNATE_SURVIVE)){
					value = 3 - getstatus(Status.ALTERNATE_SURVIVE).value;
				}else{
					value = 3;
				}
			}
			
			//Alternate Reduce By: Absorb status effects
			if (hasstatus(Status.ALTERNATE + Status.REDUCE)){
				var stattemplate:StatusTemplate = Gamedata.getstatustemplate(stat);
				
				if(stattemplate.blockedbyparallelreduce){
					var altreduceby:StatusEffect = getstatus(Status.ALTERNATE + Status.REDUCE);
					
					if (value >= altreduceby.value){
						value -= altreduceby.value;
						removestatus(Status.ALTERNATE + Status.REDUCE);
					}else{
						altreduceby.value -= value;
						altreduceby.displayvalue -= value;
						value = 0;
					}
					
					if(S.isinstring(stat, Status.ALTERNATE)){
						textparticle(Locale.variabletranslate("Blocked {statuseffect}!", {
							statuseffect: S.removefromleft(stat, Status.ALTERNATE.length) + "?"
						} ));
					}else{
						textparticle(Locale.variabletranslate("Blocked {statuseffect}!", {
							statuseffect: Locale.translate(stat) 
						} ));
					}
				}
			}
			
			if(value > 0){
				for (i in 0 ... status.length){
					if (status[i].type.toLowerCase() == stat.toLowerCase()){
						status[i].add(value);
						//Run the "wheninflicted" script
						if (status[i].scriptwheninflicted != "") status[i].runwheninflictedscript(status[i].type.toLowerCase(), value, this);
						//Run the "onanystatusinfliction" scripts
						for (j in 0 ... status.length){
							if(i != j){
								if (status[j].scriptonanystatusinfliction != "") status[j].runonanystatusinflictionscript(status[i].type.toLowerCase(), value, this);
							}
						}
						alreadyhas = true;
					}
				}
				
				if (!alreadyhas){
					var effect:StatusEffect = new StatusEffect(stat, value, this);
					
					//Run the "wheninflicted" script
					if (effect.scriptwheninflicted != "") effect.runwheninflictedscript(stat, value, this);
					//Run the "onanystatusinfliction" scripts
					for (j in 0 ... status.length){
						if (status[j].scriptonanystatusinfliction != "") status[j].runonanystatusinflictionscript(stat, value, this);
					}
					
					status.push(effect);
					if(!effect.invisible) {
						var tooltipfunc = function() {
							effect.updatedescription();
							var desc:Array<String> = ["[" + effect.symbol + "]_" + Locale.translate(effect.name) + "[]"];
							for (v in effect.description) desc.push(Locale.translate(v));
							return desc;
						}
						TooltipManager.addtooltipwithfunc((isplayer?"player":"enemy") + "_" + effect.type, tooltipfunc, "status", "gamefontsmall", Col.WHITE, Text.LEFT);
					}
				}else{
					//Update the tooltip!
					for (i in 0 ... status.length){
						if (status[i].type.toLowerCase() == stat.toLowerCase()){
							var effect:StatusEffect = status[i];
							if (!effect.invisible) {
								var tooltipfunc = function() {
									effect.updatedescription();
									var desc:Array<String> = ["[" + effect.symbol + "]_" + Locale.translate(effect.name) + "[]"];
									for (v in effect.description) desc.push(Locale.translate(v));
									return desc;
								}
								TooltipManager.updatetooltipwithfunc((isplayer?"player":"enemy") + "_" + effect.type, tooltipfunc, Col.WHITE, Text.LEFT);
							}
						}
					}
				}
				
				//Instant effects: Alternate Silence kicks in as soon as it's inflicted
				if (stat == Status.ALTERNATE + Status.SILENCE){
					if (name != "Bear"){ // Bear is immune
						if (limitbreak != null){
							changelimitbreak(template.alternatelimit);
						}
					}
				}
			}
		}
	}
	
	public function hasequipment(eq:String):Bool{
		for (i in 0 ... equipment.length){
			if (equipment[i].name.toLowerCase() == eq.toLowerCase()){
				return true;
			}
		}
		return false;
	}
	
	public function hadstatus(stat:String):Bool{
		for (i in 0 ... status.length){
			if (status[i].type == stat.toLowerCase()){
				if(status[i].displayvalue > 0)	return true;
			}
		}
		return false;
	}
	
	public function hasstatus(stat:String):Bool{
		for (i in 0 ... status.length){
			if (status[i].type == stat.toLowerCase()){
				if(status[i].value > 0)	return true;
			}
		}
		return false;
	}
	
	public function getstatus(stat:String):StatusEffect{
		if (Rules.hasalternate(stat)) stat = Status.ALTERNATE + stat;
		
		for (i in 0 ... status.length){
			if (status[i].type == stat.toLowerCase()){
				return status[i];
			}
		}
		return null;
	}
	
	public function onstatusremove(stat:String){
		//Repair Alternate Silence when it's removed
		if (stat == Status.ALTERNATE + Status.SILENCE){
			if (name != "Bear"){ // Bear is immune
				if (limitbreak != null){
					//TO DO: Support permanent limit break changes via a bool in changelimitbreak?
					changelimitbreak(template.limit);
				}
			}
		}
	}
	
	public function removestatus(stat:String){
		for (i in 0 ... status.length){
			if (status[i].type == stat.toLowerCase() || stat == Status.ALL){
				if(!status[i].invisible) {
					TooltipManager.removetooltip((isplayer?"player":"enemy") + "_" + status[i].type);
				}
				onstatusremove(status[i].type);
				
				status.splice(i, 1);
				return;
			}
		}
	}
	
	public function decrementstatus(stat:String, removeifempty:Bool = false){
		if(hasstatus(stat)){
			var status:StatusEffect = getstatus(stat);
			if (status.value >= 1){
				status.value--;
				if (removeifempty){
					if (status.value <= 0){
						removestatus(stat);
					}
				}
			}
		}
	}
	
	public function screenposition():Int{
		//Basically: Are we at the top or the bottom of the screen?
		if (Game.player == this){
			return Gfx.BOTTOM;
		}
		return Gfx.TOP;
	}
	
	public function initvariables(){
		equipment = [];
		status = [];
		
		charactertemplate = null;

		statsicon = new HaxegonSprite(0, 0);
		statsicon.uses4kasset = Screen.use4kassets;
		for (data in Gamedata.charactertemplates) {
			if (Screen.use4kassets) {
				statsicon.addimageframe('${data.icon}_4k');
			} else {
				statsicon.addimageframe('${data.icon}_1080');
			}
		}
		
		textfield = [];
		for (i in 0 ... 6) textfield.push(new Print());
		healthbar = new Healthbar();
		
		limitbarback = new HaxegonSprite(0, 0, "ui/combat/limitbar_back", 0 , 0);
		limitbarfront = new HaxegonSprite(0, 0, "ui/combat/limitbar_front", 0 , 0);
		limitbarhighlight = new HaxegonSprite(0, 0, "ui/combat/highlightbar", 0 , 0);
		limitbarshadow = new HaxegonSprite(0, 0, "ui/combat/shadowbar", 0 , 0);
		limitbarglow = new HaxegonSprite(0, 0, "ui/combat/limitbar_glow", 0, 0);
		limitbarfront.scale9grid(37, 11, 560, 80);
		blindshadow = new HaxegonSprite(0, 0, "ui/combat/shadowbar", 0 , 0);
		blindshadowtext = new Print();
		
		statusbarback = new HaxegonSprite(0, 0, "ui/combat/statusbar_back", 0 , 0);
		statusbarstate = 0;
		statusbaroffset = new Point(0, 0);
		
		if (dicepool != null){ if (dicepool.length > 0){	for (d in dicepool) d.dispose(); } }
		dicepool = [];
		
		level = 1;
		dice = 1;
		maxhp = 0;
		maxmana = 0;
		usedupgrade = 0;
		gold = 0;
		usecpuinsteadofdice = false;
		
		shaketime = 0;
		tinttime = 0;
		
		limitbreak = null;
		alternatelimitbreak = null;
		limitmax = 0;
		limitvalue = 0;
		graphicxoff = 0;
		graphicyoff = 0;
		
		layout = EquipmentLayout.EQUIPMENT;
		
		equipmentused = 0;
		showhploss = 0;
		equipmentslotsleft = 0;
		
		hassuper = false;
	}
	
	/* This is called from an akward place: display is handled elsewhere
	 * It's in a loop that "initialises" the conversation, and then returns true when it's over */
	//valid types: lastwords1, lastwords2, lastwords3, lastwords_iftheywin, lastwords_endgame
	public function lastwordscomplete(type:String){
		if (lastwordstate == 0){
			lastwordstate = 1;
			lastwords_selected = type;
		}
		if (lastwordstate == 2){
			return true;
		}
		return false;
	}
	
	/* This is called from an akward place: display is handled elsewhere
	 * It's in a loop that "initialises" the conversation, and then returns true when it's over */
	public function firstwordscomplete(){
		if (firstwordstate == 0){
			firstwordstate = 1;
			firstwords_selected = "firstwords1";
		}
		if (firstwordstate == 2){
			return true;
		}
		return false;
	}
	
	public var lastwordstate:Int;
	public var firstwordstate:Int;
	
	public function showfirstandlastwords(position:Int = -300000){
		var xposition:Float = x + (50 * 6);
		var yposition:Float = (15 * 6);
		var charicon:String = "";
		var charcol:Int = Col.YELLOW;
		
		if (position == Text.CENTER){
			xposition = Screen.widthmid;
		}
		if (LadyLuckEnemy.active){
			xposition -= 900;
			yposition = 30 * 6;
			charcol = Col.YELLOW;
			charicon = "characters/misc/charicon_ladyluck";
		}
		
		if (firstwordstate > 0 && firstwords_selected != ""){
			var firstwordprogress:Int = 0;
			var translatedfirstwords:Array<String> = null;
			switch(firstwords_selected){
				case "firstwords1": translatedfirstwords = Game.splitandtrim(Locale.translate(firstwords), "||");
			}
			
			if (template.kludge_introfirstwords){
				//Special case! In the lady luck intro, we have special controls to do a quick back and
				//forth dialogue between the players and lady luck. Might make this more versatile later.
				for (i in 0 ... translatedfirstwords.length){
					while (textboxes.length <= i){
						textboxes.push(new Textbox());
						textboxesaudio.push("");
					}
					var textbox:Textbox = textboxes[i];
					if (i <= firstwordprogress){
						if (i == 1 || i == 3 || i == 4){
							var othername:String = Game.player.name;
							var othercol:Int = Col.WHITE;
						  var otherchatvoice:String = "chat_warrior";
							var othercharicon:String = "characters/" + othername.toLowerCase() + "/charicon_" + othername.toLowerCase();
							switch(othername){
								case "Warrior":
									othercol = Col.LIGHTBLUE;
									otherchatvoice = "chat_warrior";
								case "Thief":
									othercol = Col.multiplylightness(Col.GREEN, 1.25);
									otherchatvoice = "chat_thief";
								case "Robot":
									othercol = 0xDDDDDD;
									otherchatvoice = "chat_robot";
								case "Inventor":
									othercol =  0xffe48d;
									otherchatvoice = "chat_inventor";
								case "Witch":
									othercol = 0xb496ec;
									otherchatvoice = "chat_witch";
								case "Jester": 
									othercol = Col.multiplylightness(Col.RED, 1.25);
									otherchatvoice = "chat_jester";
							}
							if (textbox.displaytitle(100, Screen.height - 100, othername, othercol, Game.splitwithlangdirection(translatedfirstwords[i],"|"), true, Gfx.LEFT, Gfx.BOTTOM, otherchatvoice, othercharicon)){
								if (firstwordprogress == i) firstwordprogress++;
							}
							if (textboxesaudio[i] == ""){
								//Say something now, then mark it as "said"
								if (i == 4){
									AudioControl.play(otherchatvoice + "_voice", "personality");
								}else{
									AudioControl.play(otherchatvoice + "_voice", "determined");
								}
								textboxesaudio[i] = "done";
							}
						}else{
							if (textboxesaudio[i] == ""){
								//Say something now, then mark it as "said"
								var ignorethisone:Bool = false;
								if (chatvoice != "chat_ladyluck") ignorethisone = true;
								if (i > 0){
									if ((chatvoice + "_voice" + ":scary") == textboxesaudio[i - 1]){
										ignorethisone = true;
									}
								}
								if (i == 8){
									AudioControl.play(chatvoice + "_voice", "scary");
								}else{
									if (!ignorethisone){
										if (i == 2){
											AudioControl.play(chatvoice + "_voice", "thinking");
										}else{
											AudioControl.play(chatvoice + "_voice", "scary");
										}
									}
								}
								textboxesaudio[i] = chatvoice + "_voice" +  ":scary";
							}
							if (textbox.displaytitle(xposition, yposition, name, charcol, Game.splitwithlangdirection(translatedfirstwords[i],"|"), true, position, Gfx.TOP, chatvoice, charicon)){
								if (firstwordprogress == i) firstwordprogress++;
							}
						}
					}
				}
			}else{
				for (i in 0 ... translatedfirstwords.length){
					while (textboxes.length <= i){
						textboxes.push(new Textbox());
						textboxesaudio.push("");
					}
					var textbox:Textbox = textboxes[i];
					if (i <= firstwordprogress){
						if (textboxesaudio[i] == ""){
							//Say something now, then mark it as "said"
							var ignorethisone:Bool = false;
							if (chatvoice != "chat_ladyluck") ignorethisone = true;
							if (!ignorethisone){
								AudioControl.play(chatvoice + "_voice", "scary");
							}
							textboxesaudio[i] = "done";
						}
						if (textbox.displaytitle(xposition, yposition, name, charcol, Game.splitwithlangdirection(translatedfirstwords[i],"|"), true, position, Gfx.TOP, chatvoice, charicon)){
							if (firstwordprogress == i) firstwordprogress++;
						}
					}
				}
			}
			
			if (firstwordprogress >= translatedfirstwords.length){
				if (firstwordstate == 1){
					if (template.kludge_introfirstwords){
						//Re-enable this later if you want it
						template.kludge_introfirstwords = false;
					}
					firstwordstate = 2;
				}
			}
		}
		
		if (lastwordstate > 0 && lastwords_selected != ""){
			var lastwordprogress:Int = 0;
			var translatedlastwords:Array<String> = null;
			switch(lastwords_selected){
				case "lastwords1": translatedlastwords = Game.splitandtrim(Locale.translate(lastwords1), "||");
				case "lastwords2": translatedlastwords = Game.splitandtrim(Locale.translate(lastwords2), "||");
				case "lastwords3": translatedlastwords = Game.splitandtrim(Locale.translate(lastwords3), "||");
				case "lastwords_iftheywin": translatedlastwords = Game.splitandtrim(Locale.translate(lastwords_iftheywin), "||");
				case "lastwords_endgame": translatedlastwords = Game.splitandtrim(Locale.translate(lastwords_endgame), "||");
				case "lastwords_finale": translatedlastwords = Game.splitandtrim(Locale.translate(Game.selectedlastwords_text), "||");
			}
			for (i in 0 ... translatedlastwords.length){
				while (textboxes.length <= i){
					textboxes.push(new Textbox());
					textboxesaudio.push("");
				}
				var textbox:Textbox = textboxes[i];
				if (i <= lastwordprogress){					
					if (textboxesaudio[i] == ""){
						//Say something now, then mark it as "said"
						
						textboxesaudio[i] = "done";
					}
					if (textbox.displaytitle(xposition, yposition, name, charcol, Game.splitwithlangdirection(translatedlastwords[i],"|"), true, position, Gfx.TOP, chatvoice, charicon)){
						if (lastwordprogress == i) lastwordprogress++;
					}
				}
			}
			
			if (lastwordprogress >= translatedlastwords.length){
				if (lastwordstate == 1){
					lastwordstate = 2;
				}
			}
		}
	}

	public function updatetranslations() {
		if (textboxes != null) {
			for(textbox in textboxes) {
				if(textbox.dismissed) continue;
				textbox.reload();
			}
		}
	}
	
	public function cleanuplastwords(){
		firstwordstate = 0;
		firstwords_selected = "";
		
		lastwordstate = 0;
		lastwords_selected = "";
		
		if (textboxes != null){
			for (i in 0 ... textboxes.length){
				textboxes[i].dispose();
			}
			textboxes = [];
			textboxesaudio = [];
		}
	}
	
	public function showcombatstats(position:Float, xp:Int, yp:Int, context:Int = 0, showlimitbreak:Bool = false){
		if (!Screen.enabledisplay_combatstats) return;
		var alignment:Int = Gfx.LEFT;
		
		if (position == Gfx.LEFT){
			xp += Std.int(x + 130 * 6);
			yp += Std.int(y + 42 * 4);
		}else if (position == Gfx.RIGHT){
			alignment = Gfx.RIGHT;
			xp += Std.int(x - 20 * 6);
			yp += Std.int(y + 14 * 6);
		}else if (position == Gfx.CENTER){
			alignment = Gfx.RIGHT;
			xp = Screen.width - 220 * 6;
			yp = Screen.height - 45 * 6;
		}else{
			
		}
		
		if (showhploss > 0){
			xp += Random.int( -3 * 6, 3 * 6);
			yp += Random.int( -3 * 6, 3 * 6);
		}
		
		Locale.gamefont.change();
		var showdice:Bool = true;
		if (usecpuinsteadofdice) showdice = false;
		//Show dice/gold
		if (context == 2){
			Text.align = Text.LEFT;
			if (hassuper){
				textfield[0].drawno_translate(xp, yp - 14 * 6, Locale.variabletranslate("Super {enemyname}", { enemyname: Locale.translate(name)}));
			}else{
				textfield[0].drawtranslate(xp, yp - 14 * 6, name);
			}
			textfield[1].drawno_translate(xp, yp, "[gold]" + Locale.inttostring(gold));
			
			if(showdice){
				//Show both
				Text.align = Text.RIGHT;
				if (extradice + bonusdice > 0){
					textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice) + " [yellow](+" + Locale.inttostring(extradice + bonusdice) + ")");
				}else if (extradice + bonusdice < 0){
					textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice) + " [gray](-" + Locale.inttostring(Std.int(-(extradice + bonusdice))) + ")");
				}else{
					textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice), Col.WHITE);
				}
				Text.align = Text.LEFT;
			}
		}else if (context == 1){
			var displayname:String = Locale.translate(name);
			if (hassuper){
				displayname = Locale.variabletranslate("Super {enemyname}", { enemyname: Locale.translate(name)});
			}
			if (position == Gfx.RIGHT){
				//trace("TO DO: Resolve this issue and commit it. Make sure it works for all existing enemies, and also translated ones");
				if (namelength == -1){
					namelength = Symbol.width(displayname);
				}
				//trace(name + "'s name length is " + namelength);
				if (namelength >= 400){
					Text.align = Text.RIGHT;
					textfield[0].drawno_translate(xp + 66 * 6, yp, displayname);
				}else{
					Text.align = Text.LEFT;
					textfield[0].drawno_translate(xp, yp, displayname);
				}
			}else{
				Text.align = Text.LEFT;
				textfield[0].drawno_translate(xp, yp, displayname);
			}
			
			textfield[1].remove();
			
			if(showdice){
				//Just show dice
				Text.align = Text.RIGHT;
				if (extradice + bonusdice > 0){
					textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice) + " [yellow](+" +Locale.inttostring(extradice + bonusdice) + ")", Col.WHITE);
				}else if (extradice + bonusdice < 0){
					textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice) + " [gray](-" +Locale.inttostring(Std.int(-(extradice + bonusdice))) + ")", Col.WHITE);
				}else{
					textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice), Col.WHITE);
				}
				Text.align = Text.LEFT;
			}
		}else{
			Text.align = Text.LEFT;
			if (hassuper){
				textfield[0].drawno_translate(xp, yp, Locale.variabletranslate("Super {enemyname}", { enemyname: Locale.translate(name)}));
			}else{
				textfield[0].drawtranslate(xp, yp, name);
			}
			
			//Just show gold
			Text.align = Text.RIGHT;
			textfield[1].drawno_translate(xp + 100 * 6, yp, "[gold]" + Locale.inttostring(gold), Col.WHITE);
			
			textfield[2].remove();
		}
		
		yp += 14 * 6;
		
		var healthbarpos:Int = yp;
		
		var limitbreakyp = 0;
		if (showlimitbreak) {
			yp += 26 * 6;
			// draw it the last one so the glow gets drawn on top of everything
			limitbreakyp = yp;
			//drawlimitbreak(xp, yp);
			yp += 14 * 6;
		}else{
			yp += 20 * 6;
		}
		
		if (status.length > 0){
			if (statusbarstate == 0){
				statusbaroffset.setTo(0, -48 - (5 * 6) - 36);
				Game.delaycall(function(){
					Actuate.tween(statusbaroffset, 0.4 / BuildConfig.speed, { y: 0 });
				}, 0.1 / BuildConfig.speed);
			}
			statusbarstate = 1;
		}else{
			statusbarstate = 0;
		}
		
		statusbarback.x = xp;
		statusbarback.y = yp + (5 * 6) + statusbaroffset.y;
		statusbarback.alpha = 0.90;
		
		if (context > 0){
			yp += 12;
			if (status.length > 0){
				Locale.gamefontsmall.change();
				
				var statstring:String = "";
				var actuallength:Int = 0;
				var tooltipx:Float = xp;
				var tooltipy:Float = yp + (5 * 6) + statusbaroffset.y;
				var tooltipw:Float = 0.0;
				var tooltiph:Float = 0.0;
				for (i in 0 ... status.length){
					if (!status[i].invisible) actuallength++;
				}
				
				if (actuallength == 1){
					for (i in 0 ... status.length){
						if(!status[i].invisible){
							var str = status[i].toshortString();
							var bounds = Symbol.bounds(str);
							tooltipw = bounds.width;
							tooltiph = bounds.height;
							
							if (ControlMode.showgamepadui() && tooltipw > statusbarback.width - 120) {
								// If there's no room for this tooltip next to the [L] button image, use the tiny form instead.
								str = status[i].totinyString();
								bounds = Symbol.bounds(str);
								tooltipw = bounds.width;
								tooltiph = bounds.height;
							}
							
							statstring += str;
							TooltipManager.updatehotspot((isplayer?"player":"enemy") + "_" + status[i].type, tooltipx, tooltipy, tooltipw, tooltiph);
							tooltipx += tooltipw;
							if (i != status.length - 1) {
								statstring += "  ";
								// Symbol.width("  ") doesn't work because for the text engine the space is no character and doesn't have a size
								// A space is em/4 (size / 4)
								tooltipx += (Text.size / 4) * 2;
							}
						}
					}
				}else{
					for (i in 0 ... status.length){
						if(!status[i].invisible){
							var str = status[i].totinyString();
							statstring += str;
							var bounds = Symbol.bounds(str);
							tooltipw = bounds.width;
							tooltiph = bounds.height;
							TooltipManager.updatehotspot((isplayer?"player":"enemy") + "_" + status[i].type, tooltipx, tooltipy, tooltipw, tooltiph);
							tooltipx += tooltipw;
							if (i != status.length - 1) {
								statstring += "  ";
								// Symbol.width("  ") doesn't work because for the text engine the space is no character and doesn't have a size
								// A space is em/4 (size / 4)
								tooltipx += (Text.size / 4) * 2;
							}
						}
					}
				}
				
				if (statstring > ""){
					statusbarback.draw();
					
					if (ControlMode.showgamepadui()) {
						if (this == Game.player) {
							GamepadButtonImage.draw(GamepadButton.LEFT_SHOULDER, xp + 60, yp + 14 + statusbaroffset.y + 0.5 * statusbarback.height + 12, false);
						} else {
							GamepadButtonImage.draw(GamepadButtonImage.LEFT_SHOULDER_EXTRA, xp + 60, yp + 14 + statusbaroffset.y + 0.5 * statusbarback.height + 12, false);
						}
						
						textfield[4].drawno_translate(xp + 116, yp + (2 * 6) + statusbaroffset.y, statstring, Col.WHITE, 1.0, Locale.gamefontsmall);
						
						/*
						if (this == Game.player) {
							GamepadButtonImage.draw(GamepadButton.LEFT_SHOULDER, xp + textfield[4].width + 72, yp + (2 * 6) + statusbaroffset.y + 0.5 * statusbarback.height + 12, false);
						} else {
							GamepadButtonImage.draw(GamepadButtonImage.LEFT_SHOULDER_EXTRA, xp + textfield[4].width + 72, yp + (2 * 6) + statusbaroffset.y + 0.5 * statusbarback.height + 12, false);
						}
						*/
					} else {
						textfield[4].drawno_translate(xp, yp + (2 * 6) + statusbaroffset.y, statstring, Col.WHITE, 1.0, Locale.gamefontsmall);
					}
				}else{
					statusbarback.remove();
				}

				Locale.gamefont.change();
			}
		}else{
			if (showhploss > 0){
				//FutureDraw.fillbox(xp + (showhploss * 3), yp, Std.int(100 * 6 * (hp / maxhp)), 16 * 6, 0xFF2633);
				Text.align = Text.CENTER;
				textfield[4].drawno_translate(xp + 50 * 6 + (showhploss * 3), yp + 3 * 6, Locale.inttostring(hp) + "/" + Locale.inttostring(maxhp)); 
				Text.align = Text.LEFT;
				
				//FutureDraw.drawbox(xp, yp, 100 * 6, 16 * 6, Col.WHITE);
			}else{
				if(LevelUpScreen.lastlevelexp - LevelUpScreen.nextlevelexp != 0){
					//FutureDraw.fillbox(xp, yp, Std.int(100 * 6 * ((LevelUpScreen.lastlevelexp - LevelUpScreen.nextlevelexp) / LevelUpScreen.lastlevelexp)), 16, Col.BLUE);
				}
				Text.align = Text.CENTER;
				textfield[4].drawno_translate(xp + 50 * 6, yp, Locale.translate("Level") + " " + Locale.inttostring(level) + ": " + Locale.inttostring(LevelUpScreen.lastlevelexp - LevelUpScreen.nextlevelexp) + "/" + Locale.inttostring(LevelUpScreen.lastlevelexp)); 
				Text.align = Text.LEFT;
				
				//FutureDraw.drawbox(xp, yp, 100 * 6, 16 * 6, Col.WHITE);
			}
		}
		
		var blinded:Bool = hasstatus(Status.ALTERNATE_BLIND);
		var cantseehealth:Bool = hasstatus("cannotseeenemyhealth");
		if (blinded){
			blindshadow.x = xp;
			blindshadow.y = healthbarpos + 7 * 6;
			blindshadow.draw();
			
			blindshadowtext.drawtranslate(xp + 50 * 6, healthbarpos + 7 * 6, "Blind", Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
		}else if (cantseehealth){
			blindshadow.x = xp;
			blindshadow.y = healthbarpos + 7 * 6;
			blindshadow.draw();
			
			blindshadowtext.drawtranslate(xp + 50 * 6, healthbarpos + 7 * 6, "???", Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
		}else{
			healthbar.draw(xp, healthbarpos, hp, maxhp, showhploss, (position == Gfx.LEFT && Combat.playerlowhealthwarning));
		}
		
		if(showlimitbreak) {
			drawlimitbreak(xp, limitbreakyp);
		}
	}
	
	public function showstatusbaricon(position:Float, xp:Float = 0, yp:Float = 0, remixmode:Bool = false){
		// icon
		var index = Gamedata.charactertemplates.indexOf(charactertemplate);
		if (index != -1){
			statsicon.changeimageframe(index);
			statsicon.scale = 1;
			statsicon.x = xp - 20;
			statsicon.y = yp - 15 + 140 - statsicon.height * statsicon.scale / 2;

			// TODO: maybe move this to the csv
			if(layout == EquipmentLayout.SPELLBOOK) {
				statsicon.y += 16;
			}
			
			statsicon.draw();
		}

		// name
  	if (remixmode){
			if(Rules.expenabled){
				textfield[0].drawtranslate(xp + 505, yp + 75 - Locale.headerfont.pixelsize / 2, Locale.translate("Level") + " " + Locale.inttostring(level), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
				
				// next level
				textfield[5].drawno_translate(xp + 505, yp + 110, Locale.translate("Level up in [star][]") + Locale.inttostring(LevelUpScreen.nextlevelexp), Col.WHITE, 1.0, Locale.gamefont, Text.CENTER);
			}else{
				if (hassuper){
					textfield[0].drawtranslate(xp + 315, yp + 130 - Locale.headerfont.pixelsize / 2, Locale.variabletranslate("Super {enemyname}", { enemyname: Locale.translate(charactertemplate.name)}), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
				}else{
					textfield[0].drawtranslate(xp + 315, yp + 130 - Locale.headerfont.pixelsize / 2, charactertemplate.name, Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
				}
			}
		}else{
			if (hassuper){
				textfield[0].drawtranslate(xp + 315, yp + 130 - Locale.headerfont.pixelsize / 2, Locale.variabletranslate("Super {enemyname}", { enemyname: Locale.translate(charactertemplate.name)}), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
			}else{
				textfield[0].drawtranslate(xp + 315, yp + 130 - Locale.headerfont.pixelsize / 2, charactertemplate.name, Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
			}
		}
	}
	
	public function monstermode_showstatusbar(position:Float, xp:Float = 0, yp:Float = 0, remixmode:Bool = false) {
		var alignment:Int = Gfx.LEFT;
		
		if (position == Gfx.LEFT){
			xp += 60;
			yp += Screen.height - 260;
		}else if (position == Gfx.RIGHT){
			alignment = Gfx.RIGHT;
			xp += Screen.width - 1320;
			yp += 60;
		}else if (position == Gfx.CENTER){
			alignment = Gfx.RIGHT;
			xp += Screen.width - 1320;
			yp += Screen.height - 222;
		}
		
		if (showhploss > 0){
			xp += Random.int( -18, 18);
			yp += Random.int( -18, 18);
		}
		
		showstatusbaricon(position, xp, yp, remixmode);
		
		//life bar
		if (remixmode){
			xp += 160;
		}
		xp = xp + 520 + 205;
		
		healthbar.draw(xp, yp + (12 * 6), hp, maxhp, 0);
		
		// gold and dice/cpu
		var displayname:String = Locale.translate(name);
		if (hassuper){
			displayname = Locale.variabletranslate("Super {enemyname}", { enemyname: Locale.translate(name)});
		}
		if (position == Gfx.RIGHT && displayname.length >= 9){
			Text.align = Text.RIGHT;
			textfield[1].drawno_translate(xp + 66 * 6, yp, displayname);
		}else{
			Text.align = Text.LEFT;
			textfield[1].drawno_translate(xp, yp, displayname);
		}
		
		//Just show dice
		Text.align = Text.RIGHT;
		if (extradice + bonusdice > 0){
			textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice) + " [yellow](+" + Locale.inttostring(Std.int(extradice + bonusdice)) + ")", Col.WHITE);
		}else if (extradice + bonusdice < 0){
			textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice) + " [gray](-" +Locale.inttostring(Std.int(-(extradice + bonusdice))) + ")", Col.WHITE);
		}else{
			textfield[2].drawno_translate(xp + 100 * 6, yp, "[dice]x" + Locale.inttostring(dice), Col.WHITE);
		}
		Text.align = Text.LEFT;
		
		if (Monstermode.cardlist.length == 1){
			textfield[5].drawno_translate(xp + 1100, yp + 85, Locale.translate("Last fighter"), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
		}else{
			textfield[5].drawno_translate(xp + 1100, yp + 85, Locale.variabletranslate("{totalpartysize} fighters remaining", {
					totalpartysize: Locale.inttostring(Std.int(Monstermode.cardlist.length))}), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
		}
		/*
		if (Tutorial.show_levelupinfo){
			if(!remixmode){
				// current level
				xp = xp + 570 + 205;
				textfield[4].drawno_translate(xp + 315, yp + 36, Locale.translate("Level") + " " + Locale.inttostring(level), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
				
				// next level
				textfield[5].drawno_translate(xp + 315, yp + 100, Locale.translate("Level up in [star][]") + Locale.inttostring(LevelUpScreen.nextlevelexp), Col.WHITE, 1.0, Locale.gamefont, Text.CENTER);
			}
		}*/
	}

	public function showstatusbarstats(position:Float, xp:Float = 0, yp:Float = 0, remixmode:Bool = false) {
		var alignment:Int = Gfx.LEFT;
		
		if (position == Gfx.LEFT){
			xp += 60;
			yp += Screen.height - 260;
		}else if (position == Gfx.RIGHT){
			alignment = Gfx.RIGHT;
			xp += Screen.width - 1320;
			yp += 60;
		}else if (position == Gfx.CENTER){
			alignment = Gfx.RIGHT;
			xp += Screen.width - 1320;
			yp += Screen.height - 222;
		}
		
		if (showhploss > 0){
			xp += Random.int( -18, 18);
			yp += Random.int( -18, 18);
		}
		
		showstatusbaricon(position, xp, yp, remixmode);
		
		//life bar
		if (remixmode){
			xp += 160;
		}
		xp = xp + 520 + 205;
		
		healthbar.draw(xp, yp, hp, maxhp, 0);
		
		// gold and dice/cpu
		textfield[1].drawno_translate(xp, yp + 120, "[gold]" + Locale.inttostring(gold), Col.WHITE, 1.0, Locale.gamefontsmall, Text.LEFT);

		if (usecpuinsteadofdice){
			//was healthbarback.width, changed to 597
			textfield[2].drawno_translate(xp + 597, yp + 120, "[gray]" + Locale.translate("CPU") + "[] " + Locale.inttostring(roll_target), Col.WHITE, 1.0, Locale.gamefontsmall, Text.RIGHT);
		}else{
			if (extradice + bonusdice > 0){
				textfield[2].drawno_translate(xp + 597, yp + 120, "[dice]x" + Locale.inttostring(dice) + " [yellow](+" +(extradice + bonusdice) + ")", Col.WHITE, 1.0, Locale.gamefontsmall, Text.RIGHT);
			}else if (extradice + bonusdice < 0){
				textfield[2].drawno_translate(xp + 597, yp + 120, "[dice]x" + Locale.inttostring(dice) + " [gray](-" + Std.int(-(extradice + bonusdice)) + ")", Col.WHITE, 1.0, Locale.gamefontsmall, Text.RIGHT);
			}else{
				textfield[2].drawno_translate(xp + 597, yp + 120, "[dice]x" + Locale.inttostring(dice), Col.WHITE, 1.0, Locale.gamefontsmall, Text.RIGHT);
			}
		}

		if (Tutorial.show_levelupinfo && Rules.expenabled){
			if(!remixmode){
				// current level
				xp = xp + 570 + 205;
				textfield[4].drawno_translate(xp + 315, yp + 36, Locale.translate("Level") + " " + Locale.inttostring(level), Col.WHITE, 1.0, Locale.headerfont, Text.CENTER);
				
				// next level
				textfield[5].drawno_translate(xp + 315, yp + 100, Locale.translate("Level up in [star][]") + Locale.inttostring(LevelUpScreen.nextlevelexp), Col.WHITE, 1.0, Locale.gamefont, Text.CENTER);
			}
		}
	}
	
	public var innatetriggered:Float;
	
	public function getcountdownequipment():Array<Equipment>{
		var returnlist:Array<Equipment> = [];
		for (i in 0 ... equipment.length){
			if (equipment[i].countdown > 0){
				returnlist.push(equipment[i]);
			}
		}
		return returnlist;
	}
	
	public function update(){
		if (showhploss > 0){
			showhploss -= Game.deltatime * BuildConfig.speed;
		}
		
		if (tinttime > 0){
			tinttime -= Game.deltatime * BuildConfig.speed;
		}
		
		if (shaketime > 0){
			shaketime -= Game.deltatime * BuildConfig.speed;
		}
		
		//Alternate_Lock implementation goes here:
		StatusApply.applyalternatelock(this);
		
		if (usecpuinsteadofdice){
			/* Experimenting 
			 * roll_total = 0;
			for (i in 0 ... dicepool.length){
				if(dicepool[i].assigned == null){
					roll_total += dicepool[i].basevalue;
				}
			}*/
			
			var initalposition:Float = roll_barposition;
			if (roll_barposition < roll_total * 100){
				roll_barposition += 2000 * Game.deltatime * BuildConfig.speed;
				if (roll_barposition > roll_total * 100){
					AudioControl.play("jackpot_increasecounter");
					roll_barposition = roll_total * 100;
				}else{
					if(Math.floor(initalposition / 100) != Math.floor(roll_barposition / 100)){
						AudioControl.play("jackpot_increasecounter");
					}
				}
			}
			
			if (roll_barposition > roll_total * 100){
				roll_barposition -= 2000 * Game.deltatime * BuildConfig.speed;
				if (roll_barposition < roll_total * 100){
					AudioControl.play("jackpot_reducecounter");
					roll_barposition = roll_total * 100;
				}else{
					if(Math.floor(initalposition / 100) != Math.floor(roll_barposition / 100)){
						AudioControl.play("jackpot_reducecounter");
					}
				}
			}
		}

		if (graphic != null) {
			if(graphicanimated){
				graphic.update();
			}

			/*
			// to center sprite
			if(haxegon.Input.justpressed(haxegon.Key.RIGHT)) {
				anim_helper.x += 10;
			}
			if(haxegon.Input.justpressed(haxegon.Key.LEFT)) {
				anim_helper.x -= 10;
			}
			if(haxegon.Input.justpressed(haxegon.Key.UP)) {
				anim_helper.y -= 10;
			}
			if(haxegon.Input.justpressed(haxegon.Key.DOWN)) {
				anim_helper.y += 10;
			}
			trace('${anim_helper}');
			*/
		}

		if(shadow != null) {
			shadow.update();
		}

		if(battlevfx != null) {
			battlevfx.update();
		}

		if(supersparkles != null) {
			supersparkles.update();
		}
		
		/*
		// BATTLE VFX DEBUG STUFF
		if (haxegon.Input.justpressed(haxegon.Key.A)) {
			var key = "";
			@:privateAccess {
				var i = 0;
				for(k in BattleVFX.supported.keys()) {
					if (i == battlevfx_idx) {
						key = k;
						break;
					}
					i++;
				}
				battlevfx_idx += 1;
				if (key == "") {
					battlevfx_idx = 0;
				}
			}
			battlevfx_key = key;
		}
		
		if (haxegon.Input.justpressed(haxegon.Key.S)) {
			if(battlevfx_key != "") {
				symbolparticle(battlevfx_key);
				trace('playing ${battlevfx_key}');
			}
		}

		if(haxegon.Input.justpressed(haxegon.Key.RIGHT)) {
			anim_helper.x += 10;
			trace('${anim_helper}');
		}
		if(haxegon.Input.justpressed(haxegon.Key.LEFT)) {
			anim_helper.x -= 10;
			trace('${anim_helper}');
		}
		if(haxegon.Input.justpressed(haxegon.Key.UP)) {
			anim_helper.y -= 10;
			trace('${anim_helper}');
		}
		if(haxegon.Input.justpressed(haxegon.Key.DOWN)) {
			anim_helper.y += 10;
			trace('${anim_helper}');
		}
		*/
	}
	
	public function getdicematrix() : Array<Dice> {
		var poolposition:Int = (this == Game.player) ? Gfx.BOTTOM : Gfx.TOP;
		
		// We're going to use targetx/targety to identify the positions of dice and fit them back into a position matrix.
		var dicematrix:Array<Dice> = new Array<Dice>();
		
		// Slot dice into it based on targetx/targety.
		for (i in 0 ... dicepool.length) {
			if (dicepool[i].availableorlocked()) {
				for (k in 0 ... 100) {
					var candidate:Point = getdiceposition(poolposition, k);
					if (Math.abs(candidate.x - dicepool[i].targetx) < 120 && Math.abs(candidate.y - dicepool[i].targety) < 120) {
						dicematrix[k] = dicepool[i];
						break;
					}
				}
			}
		}
		
		// Position remaining dice that were nowhere near anything.
		for (i in 0 ... dicepool.length) {
			if (dicepool[i].availableorlocked() && dicematrix.indexOf(dicepool[i]) == -1) {
				var bestposition:Int = -1;
				var bestdist:Float = 10000;
				
				for (k in 0 ... 100) {
					if (dicematrix[k] == null) {
						var candidate:Point = getdiceposition(poolposition, k);
						var dist:Float = Geom.distance(candidate.x, candidate.y, dicepool[i].targetx, dicepool[i].targety);
						
						if (bestposition == -1 || dist < bestdist) {
							bestposition = k;
						}
					}
				}
				
				if (bestposition != -1) {
					dicematrix[bestposition] = dicepool[i];
				}
			}
		}
		
		return dicematrix;
	}
	
	public function getdicematrixwidth() : Int {
		var poolposition:Int = (this == Game.player) ? Gfx.BOTTOM : Gfx.TOP;
		
		// How wide is the matrix?
		var matrixcolumns:Int = 1;
		var starty:Float = getdiceposition(poolposition, 0).y;
		while (getdiceposition(poolposition, matrixcolumns).y == starty) {
			++matrixcolumns;
		}
		
		return matrixcolumns;
	}

	public function placediceinmatrix(dicematrix:Array<Dice>) {
		var poolposition:Int = (this == Game.player) ? Gfx.BOTTOM : Gfx.TOP;
		
		// Apply the matrix back to the dice by setting their targetx/targety and tweening to their new positions.
		for (i in 0 ... dicematrix.length) {
			if (dicematrix[i] != null) {
				var targetpoint:Point = getdiceposition(poolposition, i);
				
				dicematrix[i].targetx = targetpoint.x;
				dicematrix[i].targety = targetpoint.y;
				
				dicematrix[i].inlerp = true;
				Actuate.tween(dicematrix[i], 0.4 / BuildConfig.speed, {x: dicematrix[i].targetx, y: dicematrix[i].targety})
					//.delay(0.2 * i / BuildConfig.speed)
					.onComplete(function(d:Dice){
						d.inlerp = false;
					}, [dicematrix[i]]);
			}
		}
	}
	
	public function arrangedice(){
		// In gamepad mode, call this after using dice to automatically fix dice positions.

		var poolposition:Int = (this == Game.player) ? Gfx.BOTTOM : Gfx.TOP;
		var dicematrix:Array<Dice> = getdicematrix();
		var matrixcolumns:Int = getdicematrixwidth();
		var matrixrows:Int = Math.ceil(dicematrix.length / matrixcolumns);
		
		// Now we sift through the matrix and rearrange all dice.
		for (i in 0 ... dicematrix.length) {
			if (dicematrix[i] == null) {
				// An empty slot. Fill it from above if possible, else fill it from forwards.
				for (k in 0 ... matrixrows) {
					if (dicematrix[i + k * matrixcolumns] != null) {
						dicematrix[i] = dicematrix[i + k * matrixcolumns];
						dicematrix[i + k * matrixcolumns] = null;
						break;
					}
				}
				
				if (dicematrix[i] == null) {
					var endofrow:Int = i - (i % matrixcolumns) + matrixcolumns;
					for (k in i + 1 ... endofrow) {
						if (dicematrix[k] != null) {
							dicematrix[i] = dicematrix[k];
							dicematrix[k] = null;
							break;
						}
					}
				}
			}
		}
		
		// Now we're going to apply this back to the dice by setting their targetx/targety and tweening to their new positions.
		placediceinmatrix(dicematrix);
	}
	
	public function makeholeindicegrid(holex:Float, holey:Float){
		// In gamepad mode, call this to open up a space in the dice grid.
		// We use this when returning a dice from a piece of equipment. It's supposed to perform the reverse of arrangedice().
		// yes, this is a hacky copy/paste. 
		
		var poolposition:Int = (this == Game.player) ? Gfx.BOTTOM : Gfx.TOP;
		var dicematrix:Array<Dice> = getdicematrix();
		var matrixcolumns:Int = getdicematrixwidth();
		var matrixrows:Int = Math.ceil(dicematrix.length / matrixcolumns);

		// Find the position to place the hole.
		var holeidx:Int = -1;
		for (k in 0 ... dicematrix.length) {
			var candidate:Point = getdiceposition(poolposition, k);
			if (Math.abs(candidate.x - holex) < 120 && Math.abs(candidate.y - holey) < 120) {
				holeidx = k;
				break;
			}
		}
		
		if (holeidx == -1) {
			// We can't make a hole here - it's not in the grid.
			return;
		}

		var holerow:Int = Math.floor(holeidx / matrixcolumns);
		var holecolumn:Int = holeidx % matrixcolumns;
		
		if (dicematrix[holerow * matrixcolumns + holecolumn] == null) {
			// There's already a hole here.
			return;
		}
		
		// Find a row that we can slide to the right.
		var purgerow:Int = holerow;
		var foundspace:Bool = false;
		while (!foundspace) {
			for (testidx in purgerow * matrixcolumns + holecolumn ... purgerow * matrixcolumns + matrixcolumns) {
				if (dicematrix.length <= testidx || dicematrix[testidx] == null) {
					foundspace = true;
					break;
				}
			}
			
			if (!foundspace) {
				++purgerow;
			}
		}
		
		// Slide this row to the right.
		var slidecolumn:Int = holecolumn;
		var slidingdice:Dice = dicematrix[purgerow * matrixcolumns + slidecolumn];
		dicematrix[purgerow * matrixcolumns + slidecolumn] = null;
		while (slidingdice != null) {
			var repdice:Dice = dicematrix[purgerow * matrixcolumns + slidecolumn + 1];
			dicematrix[purgerow * matrixcolumns + slidecolumn + 1] = slidingdice;
			slidingdice = repdice;
			++slidecolumn;
		}
		
		// Slide columns up.
		if (purgerow > holerow) {
			for (i in 0 ... purgerow - holerow) {
				var riserow:Int = purgerow - i;
				dicematrix[riserow * matrixcolumns + holecolumn] = dicematrix[(riserow - 1) * matrixcolumns + holecolumn];
			}
		}
		
		// Target space is now clear.
		dicematrix[holerow * matrixcolumns + holecolumn] = null;
		
		// Now we're going to apply this back to the dice by setting their targetx/targety and tweening to their new positions.
		placediceinmatrix(dicematrix);
		
	}
	
	public function textparticle(txt:String){
		Particles.create(x + particlex + 40 * 6 + Random.int( -10 * 6, 10 * 6), y + particley + 10 * 6, particledir, "text", txt);
	}
	
	public function hplossparticle(amount:Int){
		Particles.create(x + particlex  + 50 * 6 + Random.int( -10 * 6, 10 * 6), y + particley + 10 * 6, particledir, "text", "[150%]" + Locale.inttostring(amount));
		showhploss = 0.25;
	}
	
	public function symbolparticle(sym:String){
		if(battlevfx.issupported(sym)) {
			if(sym.indexOf("attack_") > -1 && battlevfx.isplaying()) {
				// skip
			} else {
				battlevfx.play(sym, x + particlex + vfxoffset.x, y + particley + vfxoffset.y);
			}
			/*
			battlevfx.play(sym, 
			  x + particlex + vfxoffset.x + anim_helper.x, 
				y + particley + vfxoffset.y + anim_helper.y);
			*/
		} else {
			/* Don't create symbol particles any more, that hasn't been a thing since the pre-itch days, geez
			 * tint(Symbol.symbolcol[Symbol.symboltile.get(sym)]);
			for(i in 0 ... 10){
				Particles.create(x + particlex + 40 * 6 + Random.int( -20 * 6, 20 * 6), y + particley + 40 * 6 + Random.int( -20 * 6, 20 * 6), 1, "symbol", "[" + sym + "]", tintcol);
			}*/
		}
	}
	
	public function reducehp(amount:Int){
		hp -= amount;
		
		for (i in 0 ... equipment.length){
			equipment[i].charge += amount;
		}
		
		if (limitbreak != null){
			limitvalue += amount;
			if (limitvalue > limitmax){
				limitvalue = limitmax;
			}
		}
		Combat.checktargetdeath();
	}
	
	public function tint(c:Int, doshake:Bool = true){
		tintcol = c;
		tinttime = 0.4;
		if (doshake){
			shaketime = 0.4;
		}
	}
	
	public function dispose(){
		cleanup();
		cleanuplastwords();
		
		for (i in 0 ... equipment.length){
			equipment[i].dispose();
		}
		
		if (limitbreak != null){
			limitbreak.remove();
		}

		if (graphic != null) {
			graphic.dispose();
			graphic = null;
			graphicanimated = false;
		}

		if(shadow != null) {
			shadow.dispose();
			shadow = null;
		}

		statsicon.dispose();
		for(p in textfield) {
			p.dispose();
		}
		healthbar.dispose();
		limitbarback.dispose();
		limitbarfront.dispose();
		limitbarhighlight.dispose();
		limitbarshadow.dispose();
		limitbarglow.dispose();
		statusbarback.dispose();
		blindshadow.dispose();
		blindshadowtext.dispose();
	}
	
	public function cleanup(){
		removestats();
		
		//anim_helper.setTo(0, 0);
		if (graphic != null) {
			graphic.remove();
		}
		if(shadow != null) {
			shadow.remove();
		}
		if (battlevfx != null) {
			battlevfx.remove();
		}
		if (supersparkles != null) {
			supersparkles.remove();
		}
	}
	
	public function removestats(){
		for (i in 0 ... textfield.length) textfield[i].dispose();
		healthbar.remove();
		limitbarback.remove();
		limitbarfront.remove();
		limitbarhighlight.remove();
		limitbarshadow.remove();
		limitbarglow.remove();
		statusbarback.remove();
	}
	
	public function show(frame:Int, xoff:Float, yoff:Float){
		if (graphic == null) return;
		var tx:Int = Std.int(x + xoff + graphicxoff);
		var ty:Int = Std.int(y + yoff + graphicyoff);
		
		if (shaketime > 0){
			tx += Random.int( -3, 3);
			ty += Random.int( -3, 3);
		}
		
		graphic.x = tx;
		graphic.y = ty;
		
		if (tinttime > 0){
			/*
			Gfx.drawtile(tx, ty, "sprites", sprite + frame);
			Gfx.imagecolor = tintcol;
			Gfx.imagealpha = 0.7;
			Gfx.drawtile(tx, ty, "sprites", sprite + frame);
			Gfx.imagealpha = 1;
			Gfx.imagecolor = Col.WHITE;*/
		}else{
		//	Gfx.drawtile(tx, ty, "sprites", sprite + frame);
		}

		if(shadow != null) {
			if(Std.is(graphic, AnimatedAESprite)) {
				var anim = cast(graphic, AnimatedAESprite);
				shadow.x = graphic.x + (anim.layerWidth / 2 - shadow.width / 2) - shadowxoff;
				shadow.y = graphic.y + anim.layerHeight - shadowyoff;
				shadow.draw();
			}
		}
		
		graphic.draw();
		if(battlevfx != null) {
			battlevfx.draw();
		} 
		if(supersparkles != null) {
			supersparkles.x = tx;
			supersparkles.y = ty;
			supersparkles.draw();
		}
	}
	
	public function drawlimitbreak(tx:Float, ty:Float) {
		if (limitbreak == null) return;
		
		if (limitvalue >= limitmax) {
			limitbarglow.x = tx - 56;
			limitbarglow.y = ty - 53;
			limitbarglow.alpha = 0.7 + (Math.sin(Core.time * 6) * 0.1);
			limitbarglow.draw();
		} else {
			limitbarglow.remove();
		}

		limitbarback.x = tx;
		limitbarback.y = ty;
		limitbarback.draw();

		TooltipManager.updatehotspot('player_limitbreak', limitbarback.x, limitbarback.y, limitbarback.width, limitbarback.height);
		if (limitvalue >= limitmax){
			TooltipManager.updatetooltipline('player_limitbreak', 2, {text:"[yellow]Ready to use[]"}, Col.WHITE, "gamefontsmall", Text.CENTER);
		}else{
			TooltipManager.updatetooltipline('player_limitbreak', 2, {text:"[gray][medium](ready in {limitbreakhp} hp)[]", variables:{ limitbreakhp: Locale.inttostring(Std.int(limitmax - limitvalue)) }}, Col.WHITE, "gamefontsmall", Text.CENTER);
		}
		
		limitbarfront.alpha = 0.75;
		
		limitbarfront.x = tx;
		limitbarfront.width = Math.ceil(limitbarback.width * (limitvalue / limitmax));
		limitbarfront.y = ty;
		
		limitbarfront.draw();

		Locale.headerfont.change();
		Text.align = Text.CENTER;
		
		var silenced:Bool = hasstatus(Status.SILENCE);
		if (silenced){
			limitbarshadow.x = tx;
			limitbarshadow.y = ty;
			limitbarshadow.draw();
			
			textfield[5].drawtranslate(tx + 597 / 2, ty - 3, "silenced", Col.WHITE, 1.0, Locale.headerfont);
		}else{
			limitbarshadow.remove();
			
			if (ControlMode.showgamepadui()) {
				var buttonhighlight:Bool = false;
				var vibratebutton:Bool = false;
				
				limitbarhighlight.remove();

				var showbuttonprompt:Bool = ControlMode.showgamepadui() && !Combat.previewingequipment && !Combat.previewtransition && !Combat.flee_showprompt && !Input.suppress
										&& !Game.player.hasstatus("silence") && !Combat.preventfurtheractions && Combat.playerequipmentready;
				
				if (limitvalue < limitmax){
					textfield[5].translate(tx + 597 / 2 + (showbuttonprompt ? -42 : 0), ty - 3, limitbreak.name, 0xf2ed96, 1.0, Locale.headerfont);
					if (textfield[5].x - 0.5*textfield[5].width < limitbarback.x + 10) {
						textfield[5].drawtranslate(limitbarback.x + 10 + 0.5*textfield[5].width, ty - 3, limitbreak.name, 0xf2ed96, 1.0, Locale.headerfont);
					} else {
						textfield[5].draw();
					}
				}else{
					textfield[5].translate(tx + 597 / 2 + (showbuttonprompt ? -42 : 0), ty - 3, limitbreak.name, Col.multiplylightness(0xf2ed96, 1.3), 1.0, Locale.headerfont);
					if (textfield[5].x - 0.5*textfield[5].width < limitbarback.x + 10) {
						textfield[5].drawtranslate(limitbarback.x + 10 + 0.5*textfield[5].width, ty - 3, limitbreak.name, Col.multiplylightness(0xf2ed96, 1.3), 1.0, Locale.headerfont);
					} else {
						textfield[5].draw();
					}
					
					if (ControlMode.showgamepadui() && Combat.limitbreaksfx && Combat.showgamepadcontrols() && !Combat.selectspellslotmode && !Combat.playerhaswoncombat && !Settings.isopen() && (!Combat.limitbreakanimation.visible || Combat.limitbreakanimation.frame > 0.75 * Combat.limitbreakanimation.totalframes)) {
						vibratebutton = !LimitBreakPrompt.showing;
					}
					buttonhighlight = true;
				}

				if (showbuttonprompt) {
					var buttonx:Float = textfield[5].x + 0.5 * textfield[5].width + 46;//tx + 592 / 2 - 42 + 0.5 * textfield[5].width + 46;
					var buttony:Float = ty + 0.5 * limitbarback.height + 6;
					
					if (vibratebutton) {
						buttonx += Random.float( -3, 3);
						buttony += Random.float( -3, 3);
					}
				
					var buttonsymbol:Int = GamepadButton.RIGHT_SHOULDER;
					if (buttonhighlight) {
						GamepadButtonImage.draw(buttonsymbol, buttonx, buttony, false);
					} else {
						GamepadButtonImage.draw(buttonsymbol, buttonx, buttony, false, 0xf2ed96);
					}
				}
			} else {
				if (limitvalue < limitmax){
					if (MultiTouch.hover(limitbarfront.x, limitbarfront.y, limitbarfront.width, limitbarfront.height)){
						limitbarhighlight.x = tx;
						limitbarhighlight.y = ty;
						limitbarhighlight.alpha = 0.3;
						limitbarhighlight.draw();
					}else{
						limitbarhighlight.remove();
					}
					textfield[5].drawtranslate(tx + 597 / 2, ty - 3, limitbreak.name, 0xf2ed96, 1.0, Locale.headerfont);
				}else{
					limitbarhighlight.remove();
					textfield[5].drawtranslate(tx + 597 / 2, ty - 3, limitbreak.name, Col.multiplylightness(0xf2ed96, 1.3), 1.0, Locale.headerfont);
				}
			}
		}
		Text.align = Text.LEFT;
		Locale.gamefont.change();
	}
	
	public function hidelimitbreak(){
		TooltipManager.updatehotspot('player_limitbreak', 0, -Screen.height, limitbarback.width, limitbarback.height);
	}

	public function limitready():Bool{
		if (Combat.commandqueue.length > 0){
			if (Combat.commandqueue[0].cmd == "playerturn" && Combat.commandqueue[0].contents == "allocatedice"){
				return (limitvalue >= limitmax);
			}
		}
		return false;
	}
	
	public function changelimitbreak(skillname:String){
		if (limitbreak != null){
			if (skillname != limitbreak.name){
				displayobjects.TooltipManager.removetooltip("player_limitbreak");		
				limitbreak.remove();
				
				limitbreak = new Skill(skillname, 0);
				var tooltiptext = [
					{text: ""},
					{text: limitbreak.description},
					{text: ""},
				];
				displayobjects.TooltipManager.addtooltip("player_limitbreak", tooltiptext, "limitbreak", "gamefontsmall", Col.WHITE, Text.CENTER);
				displayobjects.TooltipManager.updatetooltipline("player_limitbreak", 0, {func: function() return "[yellow]" + Locale.translate(limitbreak.name) + "[]"}, Col.WHITE, "headerfont", Text.CENTER);
			}
		}	
	}

	/* Currently this function is only used for Witch's Throw Dice attack. It doesn't count consumed,
	 * assigned or locked dice when figuring out how many dice remain. */
	public function remainingdice():Int{
		var rdice:Int = 0;
		for (d in dicepool){
			if(!d.consumed && !d.locked){
				if(d.assigned == null){
					rdice++;
				}
			}
		}
		return rdice;
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
				gamevar.set(v, 0);
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
	
	public function endturnnow(){
		doendturnnow = true;
		AudioControl.play("clicked_nextturn");
		Tutorial.reportevent("playerendturn");

		if (isplayer) {
			Combat.gamepad_dicemode = false;
			Combat.gamepad_buttonmode = false;
		}
		
		Combat.equipmentfreezekludge = 0;
		Combat.addcommand("wait", "playerequipmentanimating");
		Combat.addcommand("playertidyup");
	}
	
	public function spaceleft():Int{
		var space:Int = 8;
		if (layout == EquipmentLayout.EQUIPMENT){
			for (e in equipment){
				space -= e.size;
			}
		}else{
			space = 0;
		}
		return space;
	}

	
	public var doendturnnow:Bool;
	
	public var gamevar:Map<String, Dynamic>;
	
	//Animations
	public var showhploss:Float;
	public var tintcol:Int;
	public var tinttime:Float;
	public var shaketime:Float;
	
	public var name:String;
	public var namelength:Float;
	public var type:String;
	public var description:String;
	public var graphic:ISprite;
	public var graphicanimated:Bool;
	public var graphicxoff:Int;
	public var graphicyoff:Int;
	public var x:Float;
	public var y:Float;
	public var particlex:Float;
	public var particley:Float;
	public var particledir:Int;
	public var ai:String;
	public var voice:String;
	public var chatvoice:String;
	public var hassuper(default, set):Bool;

	public var shadow:ISprite;
	public var shadowxoff:Int = 0;
	public var shadowyoff:Int = 0;

	inline function set_hassuper(v:Bool):Bool {
		hassuper = v;
		/*
		// Super sparkles disabled for now
		if(hassuper) {
			if(supersparkles == null) {
				supersparkles = AnimatedAESprite.loadFromJSON('data/graphics/ui/sparkles/data.json', Art.getsparklesatlas());
			}
		} else if (supersparkles != null) {
			supersparkles.dispose();
			supersparkles = null;
		}
		*/
		return hassuper;
	}
	
	public function toString():String{
		var fields:Array<String> = Type.getInstanceFields(Type.getClass(this));
		fields.remove("toString");
		var output:String = name + ": {";
		for (i in 0 ... fields.length){
			output += fields[i] + ": \"" + Reflect.field(this, fields[i]) + "\"";
			if (i < fields.length - 1){
				output += ",\n";
			}
		}
		output += "}";
		return output;
	}
	
	public var charactertemplate:CharacterTemplate;
	public var statsicon:HaxegonSprite;
	public var textfield:Array<Print>;
	public var healthbar:Healthbar;
	public var limitbarback:HaxegonSprite;
	public var limitbarfront:HaxegonSprite;
	public var limitbarhighlight:HaxegonSprite;
	public var limitbarshadow:HaxegonSprite;
	public var limitbarglow:HaxegonSprite;
	public var statusbarback:HaxegonSprite;
	public var statusbarstate:Int;
	public var statusbaroffset:Point;
	public var blindshadow:HaxegonSprite;
	public var blindshadowtext:Print;

	public var battlevfx:BattleVFX;
	public var vfxoffset:Point;

	public var supersparkles:ISprite;
	
	public var dice:Int;
	public var bonusdice:Int;
	public var extradice:Int;
	public var bonusdicenextturn:Int;
	public var dicepool:Array<Dice>;
	
	public var hp:Int;
	public var maxhp:Int;
	public var mana:Int;
	public var maxmana:Int;
	
	public var level:Int;
	public var fightswon:Int;
	public var fightsfled:Int;
	public var gold:Int;
	public var usedupgrade:Int;
	
	public var hasstolencard:Bool;
	public var stolencard:Equipment;
	public var equipmentused:Int;
	public var layout:EquipmentLayout;
	
	public var limitbreak:Skill;
	public var alternatelimitbreak:Skill;
	public var limitvalue:Int;
	public var limitmax:Int;
	//public var limitbar:Float;
	
	public var roll_total:Int;
	public var roll_range:Int;
	public var roll_totaldice:Int;
	public var roll_realtotal:Int;
	public var roll_target:Int;
	public var roll_barposition:Float;
	public var roll_jackpot:Int;
	public var roll_offset:Int; //Modifier to CPU values on roll, e.g. -1 will add 1 less CPU per roll
	public var roll_error:Bool;
	public var roll_jackpotbonus:Int;
	
	public var equipment:Array<Equipment>;
	public var lastequipmentused:Equipment;
	public var equipmenthistory:Array<Equipment>;
	public var status:Array<StatusEffect>;
	public var innate:Array<String>;
	public var innateypos:Int;
	
	public var scriptbeforecombat:String;
	public var scriptaftercombat:String;
	public var scriptbeforestartturn:String;
	public var scriptonstartturn:String;
	public var scriptendturn:String;
	
	public var lastwords1:String;
	public var lastwords2:String;
	public var lastwords3:String;
	public var lastwords_iftheywin:String;
	public var lastwords_endgame:String;
	public var alwaysspeaklastwords:Bool;
	public var canspeaklastwords:Bool;
	public var lastwords_selected:String;
	public var usecpuinsteadofdice:Bool;
	
	public var firstwords:String;
	public var alwaysspeakfirstwords:Bool;
	public var canspeakfirstwords:Bool;
	public var firstwords_selected:String;
	public var textboxes:Array<Textbox>;
	public var textboxesaudio:Array<String>;
	
	public var combatstatoffset:Int;
	
	public var finderskeepers:Int;
	public var template:FighterTemplate;
	
	public var isplayer:Bool;
	
	public var turnhistory:Array<TurnHistory>;
	
	public function resetturnhistory(){
		if(turnhistory != null){
			for (i in 0 ... turnhistory.length){
				turnhistory[i].dispose();
			}
		}
		
		turnhistory = [];
		
		saveturnhistory("startcombat");
	}
	
	public function saveturnhistory(when:String){
		turnhistory.push(new TurnHistory(this, when));
	}
  
	/*
	var anim_helper = new Point();
	var battlevfx_key:String = "";
	var battlevfx_idx:Int = 0;
	*/
}