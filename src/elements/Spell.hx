package elements;

import haxegon.*;
import states.*;
import displayobjects.*;
import elements.templates.SpellTemplate;
import haxegonaddons.Lerp;

@:access(states.Combat)
class Spell{
  public function new(_name:String, slot:Int, double:Bool){
		name = S.left(_name, 1).toUpperCase() + S.removefromleft(_name, 1);
		created = false;
		
		this.slot = slot;

		if (_name == ""){
			col = Pal.GRAY;
			requirements = [slot];
			requirementsmatched = [false];
			requirementsmatched_usedblinddice = [false];
		}else{
			var spelltemplate:SpellTemplate = Gamedata.getspelltemplate(name);
			col = spelltemplate.color;
			requirements = [];
			requirementsmatched = [];
			requirementsmatched_usedblinddice = [];
			
			if (double){
				requirements = [slot, slot];
				requirementsmatched = [false, false];
				requirementsmatched_usedblinddice = [false, false];
			}else{
				requirements = [slot];
				requirementsmatched = [false];
				requirementsmatched_usedblinddice = [false];
			}
		}
  }
	
	public function resetrequirements(){
		if (requirements.length == 2){
			requirementsmatched[0] = false;
			requirementsmatched[1] = false;
			requirementsmatched_usedblinddice[0] = false;
			requirementsmatched_usedblinddice[1] = false;
		}else if (requirements.length == 1){
			requirementsmatched[0] = false;
			requirementsmatched_usedblinddice[0] = false;
		}
	}
	
	public function drawpickup(e:Equipment, x:Float, y:Float, showdice:Bool){
		draw(e, x - 91, y, showdice, false, 0);
	}
	
	public function create(){
		if (!created){
			img_spellname = new Print();
			img_spellname_alt = null;
			widthchecked = 0;
			
			img_tinydice = [];
			img_tinydice.push(new TinyDiceGraphic());
			img_tinydice.push(new TinyDiceGraphic());
			
			img_spellbackground = new HaxegonSprite(Screen.halign, Screen.valign, Pal.getspellbookslot(col));
			img_spellbackground.scale9grid(44, 34, 581 - 44, 45 - 34);
			
			img_unavailablespellname = new Print();
			img_unavailablespellbackground = new HaxegonSprite(Screen.halign, Screen.valign, Pal.getspellbookslot(Pal.BLACK));
			img_unavailablespellbackground.scale9grid(44, 34, 581 - 44, 45 - 34);
			
			img_highlightspellbackground = new HaxegonSprite(Screen.halign, Screen.valign, "ui/panels/witch/spellbookslot_white");
			img_highlightspellbackground.scale9grid(44, 34, 581 - 44, 45 - 34);
			
			created = true;
		}
	}
	
	public function remove(){
		if (img_spellname != null) {
			img_spellname.remove();
		}
		
		if (img_spellname_alt != null) {
			img_spellname_alt.remove();
		}
		
		if (img_spellbackground != null) {
			img_spellbackground.remove();
		}

		if (img_unavailablespellbackground != null) {
			img_unavailablespellbackground.remove();
		}
		
		if (img_highlightspellbackground != null) {
			img_highlightspellbackground.remove();
		}
		
		if (img_tinydice != null) {
			for (i in 0 ... img_tinydice.length){
				img_tinydice[i].remove();
			}
		}
	}
	
	public function dispose(){
		remove();
		
		if (created) {
			img_spellname.dispose();
			img_spellname = null;
			widthchecked = 0;
			
			if (img_spellname_alt != null){
				img_spellname_alt.dispose();
				img_spellname_alt = null;
			}
			
			img_spellbackground.dispose();
			img_spellbackground = null;
			
			img_unavailablespellbackground.dispose();
			img_unavailablespellbackground = null;
			
			img_highlightspellbackground.dispose();
			img_highlightspellbackground = null;
			
			for (i in 0 ... img_tinydice.length){
				img_tinydice[i].dispose();
				img_tinydice[i] = null;
			}
			img_tinydice = null;
			
			created = false;
		}
	}
	
	public var img_spellname:Print;
	public var img_spellname_alt:Print;
	public var widthchecked:Int;
	public var img_spellbackground:HaxegonSprite;
	public var img_unavailablespellbackground:HaxegonSprite;
	public var img_unavailablespellname:Print;
	public var img_highlightspellbackground:HaxegonSprite;
	public var img_tinydice:Array<TinyDiceGraphic>;
	public var created:Bool;

	static var gamepadspellcursor:HaxegonSprite = null;
	
	public function showdiceinvalid(_value:Int) : Bool {
		if (Combat.gamepad_selectedequipment == null || Combat.gamepad_selectedequipment.skillcard != "witch" || !Combat.gamepad_dicemode) {
			return false;
		}
		
		if (name == ""){
			return true;
		}
		
		for (d in Game.player.dicepool) {
			if (d.available() && (d.value == _value || d.blind)) {
				return false;
			}
		}
		
		return true;
	}
	
	public function draw(e:Equipment, x:Float, y:Float, showdice:Bool = true, highlight:Bool = false, spellindex:Int){
		create();
		
		var drawalpha:Float = (e != null) ? e.gamepadalpha : 1.0;

		if (Spellbook.spells_availablethisturn[spellindex] == false){
			img_unavailablespellbackground.width =(118 + 20) * 6;
			img_unavailablespellbackground.x = x + 4 * 6;
			img_unavailablespellbackground.y = y + 2 * 6;
			img_unavailablespellbackground.alpha = drawalpha;
			img_unavailablespellbackground.draw();
			
			img_unavailablespellname.drawtranslate(x + (72 * 6), y + (5 * 6), "Unavailable", Col.WHITE, drawalpha, Locale.headerfontsmall, Text.CENTER);
			
			if (flash > 0){
				img_spellbackground.x = x + 4 * 6;
				img_spellbackground.y = y + 2 * 6;
				img_spellbackground.alpha = (0.25 + Lerp.from_value(0.75, 0, flash, 1, "sine_in")) * drawalpha;
				img_spellbackground.draw();
			}else{
				img_spellbackground.remove();
			}
			if (flash > 0){
				flash -= Game.deltatime;
				if (flash < 0){
					flash = 0;
				}
			}
			
			img_highlightspellbackground.remove();
			return;
		}
		
		if (highlight){
			img_highlightspellbackground.width =(118 + 20) * 6;
			img_highlightspellbackground.x = x + 4 * 6;
			img_highlightspellbackground.y = y + 2 * 6;
			img_highlightspellbackground.alpha = 0.25 * drawalpha;
			img_highlightspellbackground.draw();
			
			if (ControlMode.gamepad()) {
				if (gamepadspellcursor == null) {
					gamepadspellcursor = new HaxegonSprite(Screen.halign, Screen.valign, "ui/gamepad/spellslothighlight");
					gamepadspellcursor.scale9grid(44, 34, 706 - 44, 135 - 34);
					gamepadspellcursor.width = (118 + 20) * 6 + 42;
					//gamepadspellcursor.height = (118 + 20) * 6;
				}
				
				gamepadspellcursor.x = x + 2;
				gamepadspellcursor.y = y + 1;
				gamepadspellcursor.alpha = drawalpha;
				gamepadspellcursor.draw();
			}
		}else{
			img_highlightspellbackground.remove();
		}
		
		img_spellbackground.width = (118 + 20) * 6;
		
		if (flash > 0){
			img_spellbackground.x = x + 4 * 6;
			img_spellbackground.y = y + 2 * 6;
			img_spellbackground.alpha = (0.25 + Lerp.from_value(0.75, 0, flash, 1, "sine_in")) * drawalpha;
			img_spellbackground.draw();
		}else{
			img_spellbackground.x = x + 4 * 6;
			img_spellbackground.y = y + 2 * 6;
			img_spellbackground.alpha = 0.25 * drawalpha;
			img_spellbackground.draw();
		}
		if (requirements.length == 2){
			if (showdice){
				if (requirementsmatched[0] && !requirementsmatched_usedblinddice[0]){
					img_tinydice[0].alpha = 0.5 * drawalpha;
					img_tinydice[0].draw(x + 4 * 6, y + 0, 6);
				}else if (!ControlMode.showgamepadui() || !showdiceinvalid(requirements[0])) {
					img_tinydice[0].alpha = 1 * drawalpha;
					img_tinydice[0].draw(x + 4 * 6, y + 0, requirements[0] - 1);
				} else {
					img_tinydice[0].alpha = 1 * drawalpha;
					img_tinydice[0].drawinvalid(x + 4 * 6, y + 0, requirements[0] - 1);
				}
				if (requirementsmatched[1] && !requirementsmatched_usedblinddice[1]){
					img_tinydice[1].alpha = 0.5 * drawalpha;
					img_tinydice[1].draw(x + 28 * 6, y + 0, 6);
				}else if (!ControlMode.showgamepadui() || !showdiceinvalid(requirements[1])) {
					img_tinydice[1].alpha = 1 * drawalpha;
					img_tinydice[1].draw(x + 28 * 6, y + 0, requirements[1] - 1);
				}else{
					img_tinydice[1].alpha = 1 * drawalpha;
					img_tinydice[1].drawinvalid(x + 28 * 6, y + 0, requirements[1] - 1);
				}
			}else{
				if (!requirementsmatched_usedblinddice[0] && !requirementsmatched_usedblinddice[1]){
					img_tinydice[0].draw(x + 4 * 6, y + 0, 6);
					img_tinydice[1].draw(x + 28 * 6, y + 0, 6);
				}else{
					//If we used a blind dice, then don't reveal the values...
					//The first one is an unavoidable edge case, though
					img_tinydice[0].draw(x + 4 * 6, y + 0, 6);
					
					if (!requirementsmatched_usedblinddice[1]){
						img_tinydice[1].draw(x + 28 * 6, y + 0, 6);
					}else{
						img_tinydice[1].alpha = 1 * drawalpha;
						img_tinydice[1].draw(x + 28 * 6, y + 0, requirements[1] - 1);
					}
				}
			}
		}else if (requirements.length == 1){
			if (requirements[0] <= 6){
				if (showdice){
					if (requirementsmatched[0] && !requirementsmatched_usedblinddice[0]){
						img_tinydice[0].alpha = 0.5 * drawalpha;
						img_tinydice[0].draw(x + 16 * 6, y + 0, 6);
					}else if (!ControlMode.showgamepadui() || !showdiceinvalid(requirements[0])) {
						img_tinydice[0].alpha = 1 * drawalpha;
						img_tinydice[0].draw(x + 16 * 6, y + 0, requirements[0] - 1);
					}else{
						img_tinydice[0].alpha = 1 * drawalpha;
						img_tinydice[0].drawinvalid(x + 16 * 6, y + 0, requirements[0] - 1);
					}
				}else{
					if(!requirementsmatched_usedblinddice[0]){
						img_tinydice[0].draw(x + 16 * 6, y + 0, 6);
					}else{
						//If we used a blind dice, then don't reveal the value...
						img_tinydice[0].alpha = 1 * drawalpha;
						img_tinydice[0].draw(x + 16 * 6, y + 0, requirements[0] - 1);
					}
				}
			}
		}
		
		if (name == ""){
			img_spellname.drawtranslate(x + 60 * 6, y + (2 * 6), "Empty Slot", 0xAAAAAA, drawalpha, Locale.gamefontsmall, Text.LEFT);
		}else{
			//Temporarily disabling this width checking feature: gonna figure something else
			//out later
			//If playing in english, we don't need this feature
			//if (Locale.currentlanguage == DiceyLanguage.ENGLISH) widthchecked = 1;
			widthchecked = 1;
			if (widthchecked == 0){
				//Unchecked
				var translatedspellname:String = Locale.translate(name);
				if (Text.width(translatedspellname) >= 480){
					if (img_spellname_alt == null) img_spellname_alt = new Print();
					img_spellname_alt.drawno_translate(x + (135 * 6), y + (2 * 6), translatedspellname, Col.WHITE, drawalpha, Locale.gamefontsmall, Text.RIGHT);
					widthchecked = 2;
				}else{
					img_spellname.drawno_translate(x + 60 * 6, y + (2 * 6), translatedspellname, Col.WHITE, drawalpha, Locale.gamefontsmall, Text.LEFT);
					widthchecked = 1;
				}
			}else if (widthchecked == 1){
				//Regular
				img_spellname.drawno_translate(x + 60 * 6, y + (2 * 6), Locale.translate(name), Col.WHITE, drawalpha, Locale.gamefontsmall, Text.LEFT);
			}else if (widthchecked == 2){
				//Long
				img_spellname_alt.drawno_translate(x + (135 * 6), y + (2 * 6), Locale.translate(name), Col.WHITE, drawalpha, Locale.gamefontsmall, Text.RIGHT);
			}
		}
		
		if (flash > 0){
			flash -= Game.deltatime;
			if (flash < 0){
				flash = 0;
			}
		}
	}
	
	/* Returns true if the dice is accepted */
	public function adddice(d:Dice, actor:Fighter, target:Fighter):Bool{
		var actualnumber:Int = d.basevalue;
		var blinddice:Bool = d.blind;
		
		//Add this number to the spell. Queue it to be executed if it matches
		var diceadded:Bool = false;
		if(Spellbook.spells_availablethisturn[actualnumber - 1] == true){
			for (i in 0 ... requirements.length){
				if (requirements[i] == actualnumber && !requirementsmatched[i] && !diceadded){
					diceadded = true;
					requirementsmatched[i] = true;
					if (requirements.length > 0 && i < requirements.length - 1){
						flash = 1;
					}else{
						requirementsmatched_usedblinddice[i] = blinddice;
						if (!blinddice) flash = 1;
					}
				}
			}
		}
		
		var allrequirementsmatched:Bool = true;
		for (i in 0 ... requirements.length){
			if (!requirementsmatched[i]) allrequirementsmatched = false;
		}
		
		if (allrequirementsmatched){
			Game.delaycall(function(){
				for (i in 0 ... requirements.length){
					requirementsmatched[i] = false;
				}
			}, 0.5);
			
			if(!blinddice) flash = 1;
			
			Combat.enablespellslotmode();
			if (blinddice) Combat.selectspellslotmode_placingblindspell = true;
			Combat.gamepad_selectedequipment = null;
			
			Combat.gamepad_selectedslot = 1;
			for (i in 0 ... 4) {
				if (Rules.witch_randomspellslot[i].length > 0) continue;
				if (Spellbook.equipmentslots[i] == null) {
					Combat.gamepad_selectedslot = i;
					break;
				}
			}
			
			Spellbook.summonedindex = slot - 1;
			if (requirements.length == 2){
				Spellbook.dicetoreturn = [blinddice?-actualnumber:actualnumber, blinddice?-actualnumber:actualnumber];
			}else{
				Spellbook.dicetoreturn = [blinddice?-actualnumber:actualnumber];
			}
			Spellbook.summonedequipment = name;
			
			Combat.updatespellslotpreview();
		}
		
		return diceadded;
	}
	
	public function toString():String{
		return name;
	}
	
	public var name:String;
	public var requirements:Array<Int>;
	public var requirementsmatched:Array<Bool>;
	public var requirementsmatched_usedblinddice:Array<Bool>;
	
	public var flash:Float;
	
	public var col:Int;

	public var slot:Int;
}