package elements;

import haxegon.*;
import elements.templates.SpellTemplate;
import states.Combat;
import states.ViewSpellbook;
import displayobjects.FillRect;
import displayobjects.HaxegonSprite;
import displayobjects.Print;
import displayobjects.Button;
import openfl.geom.Point;
import motion.Actuate;
import lime.ui.GamepadButton;

class SpellbookPublic{
	public static function upgradeslot(slotnum:Int){
		Spellbook.upgradedslots[slotnum] = true;
	}
	
	public static function setto(spelllist:Array<String>, preparedlist:Array<String>, upgradedcount:Int){
		//Set the spellbook to this exact layout
		Spellbook.reset();
		Spellbook.precast = [ -1, -1, -1, -1];
		Spellbook.upgradedslots = [false, false, false, false];
		Spellbook.availableslots = [false, false, false, false];
		
		for (i in 0 ... spelllist.length){
			if (spelllist[i] != "empty"){
			  if (S.left(spelllist[i], 1) == "*"){
					spelllist[i] = S.removefromleft(spelllist[i], 1);
				}
				Spellbook.learnspell(spelllist[i], (i + 1));
			}
		}
		
		for (i in 0 ... preparedlist.length){
			var spellindex:Int = -1;
			for (j in 0 ... Spellbook.spells.length){
				if (Spellbook.spells[j].name == preparedlist[i]){
					spellindex = j;
					break;
				}
			}
			Spellbook.precast[i] = spellindex;
		  Spellbook.availableslots[i] = true;
		}
		
		if (upgradedcount >= 4){
			Spellbook.upgradedslots = [true, true, true, true];
		}else if(upgradedcount > 0){
			for (i in 0 ... upgradedcount){
				Spellbook.upgradedslots[Spellbook.upgradedslots.length - 1 - i] = true;
			}
		}
		
		SpellbookPublic.showspellbookinstructions = false;
	}
	
	public static function resettoinitiallayout(spelllist:Array<String>){
		//If we supply a spelllist, then reset the spellbook. (needed for Harvest Sycthe puzzle)
		if (spelllist == null) spelllist = [];
		if (spelllist.length > 0){
			for (i in 0 ... spelllist.length){
				if (spelllist[i] != "empty"){
					if (S.left(spelllist[i], 1) == "*"){
						spelllist[i] = S.removefromleft(spelllist[i], 1);
					}
					Spellbook.learnspell(spelllist[i], (i + 1));
				}
			}
		}
		
	  //Have we partially cast any spells? If so, repair them now
		for (i in 0 ... Spellbook.spells.length){
			Spellbook.spells[i].resetrequirements();
		}
		
		//Remove all existing cast spells
		var i:Int = 0;
		while(i < Game.player.equipment.length){
			if (Game.player.equipment[i].skillcard == ""){
				var e:Equipment = Game.player.equipment.splice(i, 1)[0];
				e.dispose();
			}else {
				i++;
			}
		}
		
		//Add the equipment to the current slot
		for(i in 0 ... Spellbook.equipmentslots.length){
			Spellbook.equipmentslots[i] = null;
			Spellbook.showshadow[i] = false;
		}
		
		//And replace them with our prepared spells
		for (i in 0 ... Spellbook.precast.length){
			if (Spellbook.precast[i] != -1){
				Spellbook.summon_withoutanimation(i, Game.player, new Equipment(Spellbook.spells[Spellbook.precast[i]].name, Spellbook.upgradedslots[i]));
			}
		}
	}
	
	public static function cannotchangepreparedspells(){
		_cannotchangepreparedspells = true;
	}
	
	public static function isempty(slotnum:Int):Bool{
		if (Spellbook.spells[slotnum - 1].name == "") return true;
		return false;
	}
	
	public static function spellname(slotnum:Int):String{
		return Spellbook.spells[slotnum - 1].name;
	}
	
	public static function changespell(slotnum:Int, newspell:String){
		Spellbook.learnspell(newspell, slotnum);
	}
	
	public static function changespellflash(slotnum:Int, newspell:String){
		Spellbook.learnspell(newspell, slotnum);
		if (Game.player != null){
			var spellbook:Equipment = Game.player.getskillcard();
			if (spellbook != null){
				spellbook.animate("flashandshake");
			}
		}
	}
	
	public static function erase(slotnum:Int){
		Spellbook.learnspell("", slotnum);
		for(i in 0 ... Spellbook.precast.length) {
			if(Spellbook.precast[i] == slotnum - 1) {
				Spellbook.precast[i] = -1;
			}
		}
	}
	
	public static function getspelllist():Array<String>{
		var spelllist:Array<String> = [];
		for (s in Gamedata.spelltemplates){
			spelllist.push(s.name);
		}
		return spelllist;
	}
	
	public static function getunexpectedspell():String{
		if (Spellbook.lastrandomspell == ""){
			return "Backfire";
		}
		return Spellbook.lastrandomspell;
	}
	
	public static function disablethrowdice(){
		canthrowdice = false;
	}
	
	public static function getnumpreparedslots():Int{
		var returnval:Int = 0;
		for (i in 0 ... Spellbook.precast.length) if (Spellbook.precast[i] != -1) returnval++;
		return returnval;
	}
	
	public static function getnumupgradedslots():Int{
		var returnval:Int = 0;
		for (i in 0 ... Spellbook.upgradedslots.length) if (Spellbook.upgradedslots[i]) returnval++;
		return returnval;
	}
	
	public static var canthrowdice:Bool;
	public static var showspellbookinstructions:Bool;
	public static var _cannotchangepreparedspells:Bool;
}

//Static witches spellbook class! Call Spellbook.reset() when creating a Witch to reset.
@:access(states.Combat)
class Spellbook{
	public static function reset(){
		equipmentslots = [null, null, null, null];
		upgradedslots = [false, false, false, false];
		availableslots = [true, false, false, false];
		showshadow = [false, false, false, false];
		precast = [ 0, -1, -1, -1];
		
		if (spells != null) {
			for (s in spells) {
				if (s != null) {
					s.dispose();
				}
			}
		}
		spells = [null, null, null, null, null, null];
		spells_availablethisturn = [true, true, true, true, true, true];
		spells_availablenextturn = [true, true, true, true, true, true];
		learnspell("", 1);
		learnspell("", 2);
		learnspell("", 3);
		learnspell("", 4);
		learnspell("", 5);
		learnspell("", 6);
		
		slotpositionoffset = new Point( -Screen.width, 0);
		slotposition = [];
		slotposition.push(new Point(0, Screen.heightmid - 102 * 6 - 2 * 6 + 5 * 6));
		slotposition.push(new Point(140 * 6, Screen.heightmid - 102 * 6 - 2 * 6 + 5 * 6));
		slotposition.push(new Point(0, Screen.heightmid + 2 * 6 + 5 * 6));
		slotposition.push(new Point(140 * 6, Screen.heightmid + 2 * 6 + 5 * 6));
		
		xoffset = Screen.widthmid - 218 * 6;
		allowcancel = true;
		
		initdisplay();
		
		SpellbookPublic.canthrowdice = true;
		SpellbookPublic._cannotchangepreparedspells = false;
		SpellbookPublic.showspellbookinstructions = true;
	}
	
	public static function createspell(name:String):Spell{
		var double:Bool = false; 
		if (name != ""){
			double = (Gamedata.getspelltemplate(name).requirements == 2);
		}
		var s:Spell = new Spell(name, -1, double);
		return s;
	}
	
	public static function cleanup(){
		//Delete all equipment
		var i:Int = 0;
		while(i < Game.player.equipment.length){
			if (Game.player.equipment[i].skillcard == ""){
				var e:Equipment = Game.player.equipment.splice(i, 1)[0];
				e.dispose();
			}else {
				i++;
			}
		}
		
		//Cleanup spellbook
		showshadow = [false, false, false, false];
		equipmentslots = [null, null, null, null];
		
		spells_availablethisturn = [true, true, true, true, true, true];
		spells_availablenextturn = [true, true, true, true, true, true];
		
		for (i in 0 ... spells.length){
			for (j in 0 ... spells[i].requirements.length){
				spells[i].requirementsmatched[j] = false;
			}
		}
		
		lastrandomspell = "";
		
		initdisplay();
	}
	
	public static function cleanupsorceress(){
		//Delete equipment created by sorceress last turn
		for (j in 0 ... Rules.witch_randomspellslot.length){
			if(Rules.witch_randomspellslot[j].length > 0){
				var i:Int = 0;
				while (i < Game.player.equipment.length){
					if (Game.player.equipment[i] == equipmentslots[j]){
						Game.player.equipment.splice(i, 1);
					}else {
						i++;
					}
				}
			}
		}
		
		
		for (j in 0 ... Rules.witch_randomspellslot.length){
			if(Rules.witch_randomspellslot[j].length > 0){
				equipmentslots[j] = null;
			}
		}
	}
	
	public static function update(){
		
	}
	
	public static function drawslot(x:Float, y:Float, slotnum:Int, alpha:Float){
		if (upgradedslots[slotnum]){
			if(equipmentslots[slotnum] == null || !showshadow[slotnum]){
				spellslot_upgradedtext[slotnum].drawtranslate(x + ((862 - 56) / 2), y + 69 * 6, "upgraded", Col.WHITE, alpha, Locale.headerfontsmall, Text.CENTER);
				spellslotimg[slotnum].frame = 1;
			}else{
				spellslot_upgradedtext[slotnum].remove();
				spellslotimg[slotnum].frame = 0;
			}
		}else{
			spellslot_upgradedtext[slotnum].remove();
			spellslotimg[slotnum].frame = 0;
		}
		spellslotimg[slotnum].x = x;
		spellslotimg[slotnum].y = y - 18;
		spellslotimg[slotnum].alpha = alpha;
		spellslotimg[slotnum].draw();
	}
	
	public static function drawactiveslot(x:Float, y:Float, slotnum:Int, alpha:Float){
		//TO DO: WITCH
		//This should be an "active" slot. I'm not sure it's ever actually used
		if (upgradedslots[slotnum]){
			if(equipmentslots[slotnum] == null || !showshadow[slotnum]){
				spellslot_upgradedtext[slotnum].drawtranslate(x + ((862 - 56) / 2), y + 69 * 6, "upgraded", Col.WHITE, alpha, Locale.headerfontsmall, Text.CENTER);
				spellslotimg[slotnum].frame = 1;
			}else{
				spellslot_upgradedtext[slotnum].remove();
				spellslotimg[slotnum].frame = 0;
			}
		}else{
			spellslot_upgradedtext[slotnum].remove();
			spellslotimg[slotnum].frame = 0;
		}
		spellslotimg[slotnum].x = x;
		spellslotimg[slotnum].y = y - 18;
		spellslotimg[slotnum].alpha = alpha;
		spellslotimg[slotnum].draw();
	}
	
	public static function getselectedslot(x:Float, y:Float, xoff:Float, yoff:Float):Int{
		for (i in 0 ... 4){
  		if (Geom.inbox(x, y, xoff + xoffset + slotposition[i].x, yoff + slotposition[i].y, 132 * 6, 102 * 6) && !Input.suppress){
	  		if (Rules.witch_randomspellslot[i].length > 0) return -1;
		    return i;	
		  }
		}
		return -1;
	}
	
	public static function drawslotnum(i:Int, xoff:Float, yoff:Float, showequipment:Bool = true, alphamult:Float = 1){
		if (Rules.witch_randomspellslot[i].length > 0){
			
		}else{
			drawslot(xoff + slotposition[i].x, yoff + slotposition[i].y, i, 0.25 * alphamult);
		}
		
		if(showequipment){
			if (equipmentslots[i] != null && !equipmentslots[i].show && equipmentslots[i].cursedimage == 0){
				if(showshadow[i]){
					if (Rules.witch_randomspellslot[i].length > 0){
						
					} else if (ControlMode.gamepad() && Combat.selectspellslotmode && Combat.gamepad_selectedslot == i) {
						
					} else {
						equipmentslots[i].render(xoff + slotposition[i].x, yoff + slotposition[i].y, false, 0.2);
					}
				}
			}
		}
	}
	
	static var gamepadslotcursor:HaxegonSprite = null;
	public static function drawgamepadslotselect(i:Int, xoff:Float, yoff:Float){
		var tx:Float = xoff + xoffset + slotposition[i].x;
		var ty:Float = yoff + slotposition[i].y;
		
		if (gamepadslotcursor == null) {
			gamepadslotcursor = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/panelhighlight_small");
			gamepadslotcursor.scale9grid(116 + 25, 171 + 42, 720 - 116, 490 - 171);
		}

		gamepadslotcursor.x = tx - 25;
		gamepadslotcursor.y = ty - 42;
		gamepadslotcursor.width = 132 * 6 + 25 + 43;
		gamepadslotcursor.height = 102 * 6 + 42 + 19;
		gamepadslotcursor.draw();
	}
	
	public static function drawselectaslottext(){
		selectaslotbacking.x = xoffset + 2 * 6;
		selectaslotbacking.y = Screen.heightmid - 102 * 6 - 27 * 6;
		selectaslotbacking.draw();
		if (Locale.currentlanguage == DiceyLanguage.KOREAN ||
				Locale.currentlanguage == DiceyLanguage.SIMPLIFIEDCHINESE ||
				Locale.currentlanguage == DiceyLanguage.TRADITIONALCHINESE ||
				Locale.currentlanguage == DiceyLanguage.JAPANESE){
			selectaslotprint.drawtranslate(xoffset + (270 * 6 - ExtendedGui.buttonwidth) / 2, Screen.heightmid - 102 * 6 - 30 * 6, "Select a slot", Col.WHITE, 1.0, Locale.gamefont, Text.CENTER);
		}else{
			selectaslotprint.drawtranslate(xoffset + (270 * 6 - ExtendedGui.buttonwidth) / 2, Screen.heightmid - 102 * 6 - 32 * 6, "Select a slot", Col.WHITE, 1.0, Locale.gamefont, Text.CENTER);
		}
		Gui.moveto(xoffset + 2 * 6 +  270 * 6 - ExtendedGui.buttonwidth, Screen.heightmid - 102 * 6 - 32 * 6);
		if(allowcancel){
			if(selectaslotcancel.showanddraw("Cancel", Pal.RED, false, GamepadButton.B)) {
				cancelslotselection();
			}
		}else{
			if (selectaslotcancel_unavailable == null){
				selectaslotcancel_unavailable = new Button();
			}
			selectaslotcancel_unavailable.unavailableshowanddraw("Cancel");
		}
	}
	
	public static function drawslots(xoff:Float, yoff:Float, showequipment:Bool = true, alphamult:Float = 1){
		for (i in 0 ... 4){
			drawslotnum(i, xoff + xoffset, yoff, showequipment, alphamult);
		}
	}

	public static function cancelslotselection() {
		if(!Combat.selectspellslotmode) return;

		Combat.disablespellslotmode();
		var returnblind = false;
		if(dicetoreturn != null){
			for (i in 0 ... dicetoreturn.length){
				if (dicetoreturn[i] < 0){
					dicetoreturn[i] = -dicetoreturn[i];
					returnblind = true;
				}
			}
		}
		
		if (returnblind){
			var actualdice:Array<Dice> = [];
			for (i in 0 ... dicetoreturn.length){
				var newdice:Dice = new Dice(0, -1000);
				newdice.basevalue = dicetoreturn[i];
				newdice.blind = true;
				actualdice.push(newdice);
			}
			Script.actionexecute(Script.load('givedice(${dicetoreturn});'), Game.player, Game.monster, 0, actualdice, null, null);
		}else{
			Script.actionexecute(Script.load('givedice(${dicetoreturn});'), Game.player, Game.monster, 0, [], null, null);
		}
	}
	
	public static function learnspell(_name:String, slot:Int){
		if (slot > 6){
			throw("Error: In Spellbook.learnspell(), cannot learn a spell in slot " + slot);
		}
		var double:Bool = false; 
		if (_name != ""){
			var spelltemplate:SpellTemplate = Gamedata.getspelltemplate(_name);
			if (spelltemplate == null){
				throw("Error: In Spellbook.learnspell(), cannot find a valid spell named \"" + _name + "\"");
			}			
			double = (spelltemplate.requirements == 2);
		}
		if (spells[slot - 1] != null) {
			spells[slot - 1].dispose();
		}
		spells[slot - 1] = new Spell(_name, slot, double);
		SpellbookPublic.showspellbookinstructions = false;
	}
	
	public static function adddice(d:Dice){
		for (i in 0 ... 6){
			if (i < spells.length){
				if (spells[i].adddice(d, Game.player, Game.monster)){
					if (d.alternateburn){
						spells_availablethisturn[d.basevalue - 1] = false;
						spells_availablenextturn[d.basevalue - 1] = false;
					}
				}				
			}
		}
	}
	
	public static function matchingspell(d:Int):Bool{
		for (i in 0 ... 6){
			if (i < spells.length){
				if (i == d - 1){
					if (spells[i].name != ""){
						return true;
					}
				}
			}
		}
		return false;
	}
	
	public static function summon(selectedslot:Int, actor:Fighter, e:Equipment){
		e.equippedby = actor;
		
		//Keymaster rule enforcement: If we're out of moves this turn, this equipment is set as unavailable.
		if (Rules.movelimit > 0){
			if (actor != null){
				if (actor == Game.player){
					if (Rules.movelimit_current == 0){
						e.availablethisturn = false;
					}
				}
			}
		}
		
		if (equipmentslots[selectedslot] != null){
			if (ControlMode.gamepad()) {
				// In gamepad mode, introduce the new equipment instantly.
				equipmentslots[selectedslot].ready = false;
				actor.equipment.remove(equipmentslots[selectedslot]);
				equipmentslots[selectedslot].dispose();
				equipmentslots[selectedslot] = null;

				summon_create(selectedslot, actor, e);
				Combat.gamepad_selectedequipment = e;
			} else {
				//First destroy old spells
				equipmentslots[selectedslot].onanimatecomplete_selectedslot = selectedslot;
				equipmentslots[selectedslot].onanimatecomplete_actor = actor;
				equipmentslots[selectedslot].onanimatecomplete_equipment = e;
				equipmentslots[selectedslot].onanimatecomplete = function(selectedslot:Int, actor:Fighter, e:Equipment){
					//Destroy this equipment, and empty the slot
					actor.equipment.remove(equipmentslots[selectedslot]);
					equipmentslots[selectedslot].dispose();
					equipmentslots[selectedslot] = null;
					summon_create(selectedslot, actor, e);
				};
				
				equipmentslots[selectedslot].animate("destroy");
			}
		}else{
			summon_create(selectedslot, actor, e);
			Combat.gamepad_selectedequipment = e;
		}
	}
	
	public static function sorceresssummon(_slot:Int, spelllist:Array<String>, delay:Float = 0){
		lastrandomspell = "";
		lastrandomspell = Random.pick(spelllist);
    summon_create(_slot, Game.player, new Equipment(lastrandomspell), delay);
	}
	
	public static function startturn(){
		for (i in 0 ... spells_availablenextturn.length){
			spells_availablethisturn[i] = spells_availablenextturn[i];
			spells_availablenextturn[i] = true;
		}
	}
	
	/* Create prepared spells before the start of combat, before turn 1 */
	public static function initpreparedspells(f:Fighter){
		for (i in 0 ... precast.length){
			if (precast[i] != -1){
				summon_withoutanimation(i, f, new Equipment(spells[precast[i]].name, upgradedslots[i]));
			}
		}
	}
	
	public static function summon_withoutanimation(selectedslot:Int, actor:Fighter, e:Equipment){
		//Add the equipment to the player inventory
		//See also: Fighter.fetchequipment, where equipment is repositioned at the start of every turn
		var placed:Bool = false;
		for (i in 0 ... actor.equipment.length){
			if(!placed){
				if (actor.equipment[i].skillcard != ""){
					actor.equipment.insert(i, e);
					placed = true;
				}
			}
		}
		if (!placed) actor.equipment.push(e);
		e.ready = true;
		actor.createsparedice(e);
		
		//Add the equipment to the current slot
		equipmentslots[selectedslot] = e;
		showshadow[selectedslot] = false;
		
		//Animate the equipment into its new position
		e.initialpos = new Point(0, 0);
		e.finalpos = new Point(0, 0);
		
		e.finalpos.x = xoffset + slotposition[selectedslot].x;
		e.finalpos.y = slotposition[selectedslot].y;
		
		e.x = e.initialpos.x = e.finalpos.x - Screen.width;
		e.y = e.initialpos.y = e.finalpos.y;

		e.displayrow = e.row = selectedslot >> 1;
		e.displaycolumn = e.column = selectedslot & 1;
		
		e.x = - Screen.width;
	}
	
	public static function summon_create(selectedslot:Int, actor:Fighter, e:Equipment, delay:Float = 0){
		//Add the equipment to the player inventory
		//See also: Fighter.fetchequipment, where equipment is repositioned at the start of every turn
		var placed:Bool = false;
		for (i in 0 ... actor.equipment.length){
			if(!placed){
				if (actor.equipment[i].skillcard != ""){
					actor.equipment.insert(i, e);
					placed = true;
				}
			}
		}
		if (!placed) actor.equipment.push(e);
		e.ready = true;
		actor.createsparedice(e);
		
		e.equippedby = actor;
		
		//Add the equipment to the current slot
		equipmentslots[selectedslot] = e;
		showshadow[selectedslot] = false;
		
		//Animate the equipment into its new position
		e.initialpos = new Point(0, 0);
		e.finalpos = new Point(0, 0);
		
		e.finalpos.x = xoffset + slotposition[selectedslot].x;
		e.finalpos.y = slotposition[selectedslot].y;
		
		e.x = e.initialpos.x = e.finalpos.x - Screen.width;
		e.y = e.initialpos.y = e.finalpos.y;
		
		e.displayrow = e.row = selectedslot >> 1;
		e.displaycolumn = e.column = selectedslot & 1;
		
		AudioControl.play("cardappear");
		Actuate.tween(e, 0.5 / BuildConfig.speed, { x: e.finalpos.x , y: e.finalpos.y })
		  .delay(delay)
			.onComplete(function(s:Int, e:Equipment){
				showshadow[s] = true;
			}, [selectedslot, e]);
	}
	
	public static function initdisplay(){
		dispose();
		
		spellslotimg = [];
		spellslot_upgradedtext = [];
		for (i in 0 ... 4){
			spellslot_upgradedtext.push(new Print());
			var newslotimg:HaxegonSprite = new HaxegonSprite(Screen.halign, Screen.valign, "ui/panels/witch/emptyslot");
			newslotimg.addimageframe("ui/panels/witch/upgradedslot");
			newslotimg.scale9grid(68, 70, 710 - 68, 453 - 70);
			newslotimg.width = 862 - 46;
			newslotimg.height = 620 + 8;
			spellslotimg.push(newslotimg);
		}
		
		selectaslotprint = new Print();
		
		selectaslotbacking = Game.createbackingpanel();
		selectaslotbacking.alpha = 0.5;
		selectaslotbacking.width = 270 * 6 - ExtendedGui.buttonwidth - 2 * 6;
		selectaslotbacking.height = 16 * 6;
		
		selectaslotcancel = new Button();
		selectaslotcancel_unavailable = null;
		backingpanel = Game.createbackingpanel();
	}
	
	public static function dispose(){
		if(spellslotimg != null){
			for (i in 0 ... spellslotimg.length){
				spellslotimg[i].dispose();
			}
		}
		
		if (spellslot_upgradedtext != null){
			for (i in 0 ... spellslot_upgradedtext.length){
				spellslot_upgradedtext[i].dispose();
			}
		}
		
		if (selectaslotprint != null){
			selectaslotprint.dispose();
		}
		
		if (selectaslotbacking != null){
			selectaslotbacking.dispose();
		}

		if (selectaslotcancel != null) {
			selectaslotcancel.dispose();
		}
		
		if (selectaslotcancel_unavailable != null){
			selectaslotcancel_unavailable.dispose();
		}
		
		if (backingpanel != null){
			backingpanel.dispose();
			backingpanel = null;
		}
	}
	
	public static var spellslotimg:Array<HaxegonSprite>;
	public static var spellslot_upgradedtext:Array<Print>;
	public static var selectaslotprint:Print;
	public static var selectaslotbacking:HaxegonSprite;
	public static var selectaslotcancel:Button;
	public static var selectaslotcancel_unavailable:Button;
	public static var dicetoreturn:Array<Int>;
	public static var backingpanel:HaxegonSprite;
	
	public static var spells:Array<Spell>;
	public static var spells_availablethisturn:Array<Bool>;
	public static var spells_availablenextturn:Array<Bool>;
	public static var equipmentslots:Array<Equipment>;
	public static var upgradedslots:Array<Bool>;
	public static var availableslots:Array<Bool>;
	public static var precast:Array<Int>;
	public static var showshadow:Array<Bool>;
	public static var slotpositionoffset:Point;
	public static var slotposition:Array<Point>;
	public static var summonedindex:Int;
	public static var summonedequipment:String;
	public static var xoffset:Float;
	public static var lastrandomspell:String;
	public static var allowcancel:Bool;
}