package elements;

import haxegon.*;
import displayobjects.*;
import openfl.geom.*;
import motion.Actuate;
import states.*;

class DeckPublic{
	public static function discardhand(){
		Deck.discardhand();
	}
	
	public static function createcopyondrawpile(actor:Fighter, equip:Equipment):Card{
		var duplicateequipment:Equipment = equip.copy();
		duplicateequipment.resetaftercombat();
		duplicateequipment.resetfornewturn("player");
		
		var duplicatecard:Card = new Card(duplicateequipment);
		Deck.drawpile.push(duplicatecard);
		
		return duplicatecard;
	}
	
	public static function copyrandomcard(actor:Fighter, equip:Equipment){
		Deck.copynextcard(actor, equip);
	}
	
	public static function copynextcard(actor:Fighter, equip:Equipment){
		Deck.copynextcard(actor, equip);
	}
	
	public static function getcard(num:Int):Card{
		for (i in 0 ... Deck.inplaypile.length){
			if (Deck.inplaypile[i].equipment.ready){
				if (num <= 0){
					return Deck.inplaypile[i];
				}
				num--;
			}
		}
		return null;
	}
	
	public static function fixcardslots(){
		Deck.cardslotoffset = [];
		for(i in 0 ... _handsize){
			Deck.cardslotoffset.push(0);
		}
	}
	
	public static function advance(delay:Float = 0){
		if (delay > 0) {
			++advancesqueued;
			Game.delaycall(function(){
				advance();
			}, delay);
			return;
		}

		if (advancesqueued > 0) {
			--advancesqueued;
		}
		
		if (advancesqueued == 0) {
			//Keymaster rule enforcement: If we're out of moves this turn, don't advance the deck.
			var allowcarddraw:Bool = true;
			if (Rules.movelimit > 0){
				if (Rules.movelimit_current == 0){
					allowcarddraw = false;
				}
			}

			if (allowcarddraw) {
				//Draw more cards
				Deck.createplaypile(Game.player);
			}
			
			if (!Combat.playerhaswoncombat && Combat.playerequipmentready) {
				Deck.rearrangeplaypile(Game.player);
			}
		}
	}
	
	public static function sethandsize(h:Int, midturn:Bool = false){
		_handsize = h;
		
		Deck.created_cardslots = false;
		Deck.cardslots_midturnchangekludge = midturn;
		if(Deck.cardslotimg != null){
			for (i in 0 ... Deck.cardslotimg.length){
				Deck.cardslotimg[i].dispose();
				Deck.cardslotimg[i] = null;
			}
			Deck.cardslotimg = [];
		}
	}
	
	private static function gethandsize():Int{
		return _handsize;
	}
	
	public static function getcards(type:String):Array<Card>{
		if (Deck.discardpile == null || Deck.inplaypile == null || Deck.drawpile == null) return [];
		
		if(type == "all"){
			var masterlist:Array<Card> = [];
			for (c in Deck.discardpile) masterlist.push(c);
			for (c in Deck.inplaypile) masterlist.push(c);
			for (c in Deck.drawpile) masterlist.push(c);
			return masterlist;
		}else if (type == "discard"){
			var discardlist:Array<Card> = [];
			for (c in Deck.discardpile) discardlist.push(c);
			return discardlist;
		}else if (type == "inplay"){
			var inplaylist:Array<Card> = [];
			for (c in Deck.inplaypile) inplaylist.push(c);
			return inplaylist;
		}else if (type == "draw"){
			var drawlist:Array<Card> = [];
			for (c in Deck.drawpile) drawlist.push(c);
			return drawlist;
		}
		return [];
	}
	
	public static function getcardlist(type:String):Array<String>{
		if(type == "all"){
			var masterlist:Array<String> = [];
			for (c in Deck.discardpile) masterlist.push(c.equipment.name + c.equipment.namemodifier);
			for (c in Deck.inplaypile) masterlist.push(c.equipment.name + c.equipment.namemodifier);
			for (c in Deck.drawpile) masterlist.push(c.equipment.name + c.equipment.namemodifier);
			return masterlist;
		}else if (type == "discard"){
			var discardlist:Array<String> = [];
			for (c in Deck.discardpile) discardlist.push(c.equipment.name + c.equipment.namemodifier);
			return discardlist;
		}else if (type == "inplay"){
			var inplaylist:Array<String> = [];
			for (c in Deck.inplaypile) inplaylist.push(c.equipment.name + c.equipment.namemodifier);
			return inplaylist;
		}else if (type == "draw"){
			var drawlist:Array<String> = [];
			for (c in Deck.drawpile) drawlist.push(c.equipment.name + c.equipment.namemodifier);
			return drawlist;
		}
		return [];
	}
	
	public static function movecardto(e:Equipment, type:String){
		//trace("moving " + e.name + e.namemodifier + " to top of " + type);
		//Find the card
		var actualcard:Card = null;
		
		for (c in Deck.discardpile){
			if (c.equipment.name + c.equipment.namemodifier == e.name + e.namemodifier){
				//trace(e.name + e.namemodifier + " is in discard pile, moving to top of " + type);
				actualcard = c;
			}
		}
		if (actualcard != null) Deck.discardpile.remove(actualcard);
		
		if (actualcard == null) {
			for (c in Deck.inplaypile){
				if (c.equipment.name + c.equipment.namemodifier == e.name + e.namemodifier){
					//trace(e.name + e.namemodifier + " is in play pile, moving to top of " + type);
					actualcard = c;
				}
			}
			if (actualcard != null) Deck.inplaypile.remove(actualcard);
		}
		
		//Reunion Jester Kludge: first attempt to find the exact equipment match,
		//then fall back to a name match only if that fails
		if (actualcard == null) {
			for (c in Deck.drawpile){
				if (c.equipment == e){
					//trace(e.name + e.namemodifier + " is in play pile, moving to top of " + type);
					actualcard = c;
				}
			}
			if (actualcard != null) Deck.drawpile.remove(actualcard);
		}
		
		if (actualcard == null) {
			for (c in Deck.drawpile){
				if (c.equipment.name + c.equipment.namemodifier == e.name + e.namemodifier){
					//trace(e.name + e.namemodifier + " is in play pile, moving to top of " + type);
					actualcard = c;
				}
			}
			if (actualcard != null) Deck.drawpile.remove(actualcard);
		}
		
		if (actualcard != null) {
			if (type == "draw"){
				Deck.drawpile.push(actualcard);
			}else if (type == "inplay"){
				Deck.inplaypile.push(actualcard);
			}else if (type == "discard"){
				Deck.discardpile.push(actualcard);
			}
		}
	}
	
	public static var _handsize:Int;
	
	public static var lookahead:Int;
	public static var snapstyle:String;
	public static var snap:Int;
	public static var snapbutton:Bool;
	public static var advancesqueued:Int = 0;
	public static var drawlimit:Int = -1;
	public static var drawlimit_bonus:Int = 0;
	public static var drawnthisturn:Int = 0;
	public static var deckbuilderstyle:Bool = false;
}

//Static Jester deck class! Call Deck.reset() when creating a Jester to reset.
class Deck{
	public static function reset(){
		if (drawpile != null){
			for (c in drawpile) c.dispose();
		}
		drawpile = [];
		
		if (inplaypile != null){
			for (c in inplaypile) c.dispose();
		}
		inplaypile = [];
		
		if (discardpile != null){
			for (c in discardpile) c.dispose();
		}
		discardpile = [];
		
		created_cardslots = false;
		cardslots_midturnchangekludge = false;
		if(Deck.cardslotimg != null){
			for (i in 0 ... Deck.cardslotimg.length){
				Deck.cardslotimg[i].dispose();
				Deck.cardslotimg[i] = null;
			}
			Deck.cardslotimg = [];
		}

		slotpositionoffset = new Point(0, 0);
		
		DeckPublic.snap = 0;
		DeckPublic.snapbutton = true;
		DeckPublic.sethandsize(3);
		DeckPublic.lookahead = 3;
		DeckPublic.snapstyle = "discard";
		DeckPublic.advancesqueued = 0;
		DeckPublic.drawlimit = -1;
		DeckPublic.drawlimit_bonus = 0;
		DeckPublic.drawnthisturn = 0;
		DeckPublic.deckbuilderstyle = false;
		
		cardslotoffset = [];
	}
	
	public static function updatejestersnapstyle(newsnapstyle:String){
		if (DeckPublic.deckbuilderstyle) return;
		
		if(DeckPublic.snapstyle != newsnapstyle){
			DeckPublic.snapstyle = newsnapstyle;
			skillcard.equipmentpanel.dispose();
			
			if (skillcard != null){
				skillcard.animate("flash");
			}
		}
	}
	
	public static function getxoffset():Float{
		return Screen.widthmid - ((4 * 160 * 6) / 2) + (((160 - 140) * 6) / 2);
	}
	
	public static function newcombat(){
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
		
		discardallcards();
		if (DeckPublic.deckbuilderstyle) movediscardtodraw();
		shuffledraw();
		
		//Reset equipment countdowns
		//If equipment is marked as once per battle, recharge it now
		//(See also: Combat.startcombat)
		for (c in discardpile){
			if (c.equipment.countdown > 0){
				c.equipment.remainingcountdown = c.equipment.countdown;
			}
			
			if (c.equipment.combination){
				Combination.reset(c.equipment);
			}
			
			c.equipment.usedthisbattle = false;
			c.equipment.charge = 0;
			c.equipment.timesused = 0;
		}
	}
	
	public static function addtodiscard(c:Card){
		discardpile.push(c);
	}
	
	public static function removecard(cardtodelete:Card){
		for (c in discardpile){
			if (c == cardtodelete){
				discardpile.remove(c);
				c.dispose();
				return;
			}
		}
		
		for (c in inplaypile){
			if (c == cardtodelete){
				inplaypile.remove(c);
				c.dispose();
				return;
			}
		}
		
		for (c in drawpile){
			if (c == cardtodelete){
				drawpile.remove(c);
				c.dispose();
				return;
			}
		}
	}
	
	public static function createcard(name:String, upgraded:Bool = false):Card{
		return new Card(new Equipment(name, upgraded, false, true));
	}
	
	public static function shufflediscard(){
		discardpile = Random.shuffle(discardpile);
	}
	
	public static function shuffledraw(){
		drawpile = Random.shuffle(drawpile);
	}
	
	public static function discardallcards(){
		for (c in drawpile)	discardpile.push(c);
		drawpile = [];
		
		for (c in inplaypile)	discardpile.push(c);
		inplaypile = [];
		
		shufflediscard();
	}
	
	public static function movediscardtodraw(){
		var finalecard:Card = null;
		for (c in discardpile){
			if (c.equipment.hastag("finale")){
				finalecard = c;
			}else{
				drawpile.push(c);
			}
		}
		discardpile = [];
		
		shuffledraw();
		if(finalecard != null) drawpile.insert(0, finalecard);
	}
	
	public static function nextdrawncardisfinalecard():Bool{
		if (drawpile.length == 1){
			if (drawpile[0].equipment.hastag("finale")) return true;
		}
		return false;
	}
	
	public static function drawcard():Card{
		if (drawpile.length <= 0) movediscardtodraw();
		if (drawpile.length <= 0) return null;
		
		var topcard:Card = drawpile[drawpile.length - 1];
		if (topcard.equipment.hastag("finale")){
			drawpile.pop();
			drawpile.insert(0, topcard);
		}
		
		return drawpile.pop();
	}
	
	public static function getactiveplaypile():Int{
		var returnval:Int = 0;
		for (i in 0 ... inplaypile.length){
		 	if (inplaypile[i].equipment.ready) returnval++;
		}
		return returnval;
	}
	
	public static function remakelists(){
		mastercardlistscrollbar = 0;
		mastercardlist = [];
		
		for (c in discardpile) mastercardlist.push(c);
		for (c in inplaypile) mastercardlist.push(c);
		for (c in drawpile) mastercardlist.push(c);
		
		mastercardlist.sort(function(a:Card, b:Card){
			return Reflect.compare(a.equipment.name.toLowerCase(), b.equipment.name.toLowerCase());
		});
		
		var finalecard:Card = null;
		for (i in 0 ... mastercardlist.length){
			if (mastercardlist[i].equipment.hastag("finale")){
				finalecard = mastercardlist[i];
			}
		}
		
		if(finalecard != null){
			mastercardlist.remove(finalecard);
			mastercardlist.push(finalecard);
		}
		
		mastercardnamelist = [];
		for (i in 0 ... mastercardlist.length){
			mastercardnamelist.push(mastercardlist[i].equipment.name + mastercardlist[i].equipment.namemodifier);
		}
	}
	
	public static function unweakenall(f:Fighter){
		for (c in discardpile) c.equipment.unweaken(true);
		for (c in inplaypile) c.equipment.unweaken(true);
		for (c in drawpile) c.equipment.unweaken(true);
	}
	
	public static function resetallcardsfornewturn(f:Fighter, _turn:String){
		for (c in discardpile) c.equipment.resetfornewturn(_turn);
		for (c in inplaypile) c.equipment.resetfornewturn(_turn);
		for (c in drawpile) c.equipment.resetfornewturn(_turn);
	}
	
	public static function resetskillsfornewturn(f:Fighter){
		for (c in discardpile) c.equipment.resetskillsfornewturn();
		for (c in inplaypile) c.equipment.resetskillsfornewturn();
		for (c in drawpile) c.equipment.resetskillsfornewturn();
	}
	
	public static function resetaftercombat(f:Fighter){
		for (c in discardpile) c.equipment.resetaftercombat();
		for (c in inplaypile) c.equipment.resetaftercombat();
		for (c in drawpile) c.equipment.resetaftercombat();
		
		Deck.endturn(f);
		
		//Reset all combinations after each fight
		for (c in discardpile){
			if (c.equipment.combination) Combination.reset(c.equipment);
		}
		
		for (c in inplaypile){
			if (c.equipment.combination) Combination.reset(c.equipment);
		}
		
		for (c in drawpile){
			if (c.equipment.combination) Combination.reset(c.equipment);
		}
	}
	
	/* Called by Fighter.fetchequipment() to populate the initial inplay pile */
	public static function createplaypile(f:Fighter){

		// Don't create anything if the layout isn't DECK
		// Fixes Reunion Warrior Call for Backup when transforming to Jester and winning the combat
		// because it will overwrite the fighter equipment with a delayed advance() call
		if(f.layout != EquipmentLayout.DECK) {
			return;
		}

		function continuetodraw():Bool{
			//Enforce turn draw limit if we're using it
			if (DeckPublic.drawlimit != -1){
				if (DeckPublic.drawnthisturn >= (DeckPublic.drawlimit + DeckPublic.drawlimit_bonus)){
					return false;
				}
			}
			return getactiveplaypile() < DeckPublic._handsize;
		}
		
		while (continuetodraw()){
			DeckPublic.drawnthisturn++;
			var drawncard:Card;
			//if (nextdrawncardisfinalecard() && activeplay > 0){
			//	drawncard = null;
			//}else{
				drawncard = drawcard();
			//}
			
			if (drawncard == null){
				break;
			}else{
				if (drawncard.equipment.onceperbattle && drawncard.equipment.usedthisbattle){
					//Once per battle cards do not count towards draw limit, if in place
					DeckPublic.drawnthisturn--;
				}
				
				inplaypile.push(drawncard);
				//initial pos is where the panel exists offscreen. We want all cards to start offscreen to the right
				drawncard.equipment.initialpos = new Point(Screen.width + (10 * 6), Screen.heightmid - (drawncard.equipment.height / 2));
				drawncard.equipment.x = drawncard.equipment.initialpos.x;
				drawncard.equipment.y = drawncard.equipment.initialpos.y;
				drawncard.equipment.displaycolumn = 10; // Stop new equipment grabbing focus from left column.
			}
		}
		
		//Now we create equipment based on these cards
		f.equipment = [];
		for (cardnum in 0 ... inplaypile.length){
			f.equipment.push(inplaypile[cardnum].equipment);
			f.createsparedice(inplaypile[cardnum].equipment);
		}
	}
	
	public static function rearrangeplaypile(f:Fighter){
		var xoffset:Float = getxoffset();
		var c:Int = 0;
		for (i in 0 ... f.equipment.length){
			//final pos is where the panel sits once it's placed
			if (f.equipment[i].ready){
				f.equipment[i].finalpos = new Point(xoffset + (c * 160 * 6), Screen.heightmid - (f.equipment[i].height / 2));
				if (f == Game.player && Combat.gamepad_deckcolumn >= c && Combat.gamepad_deckcolumn <= f.equipment[i].displaycolumn && Combat.gamepad_deckcolumn != DeckPublic._handsize) {
					f.equipment[i].displaycolumn = f.equipment[i].column = c;
					Combat.gamepad_deckcolumn = c; // Move cursor when equipment moves across this column. (Unless we're on the skillcard.)
				} else {
					f.equipment[i].displaycolumn = f.equipment[i].column = c;
				}
				c++;
			}
		}
		
		Game.equipmentplaced = 0;
		Game.equipmenttoplace = f.equipment.length;
		
		var delay:Float = 0.0;
		for (i in 0 ... f.equipment.length){
			f.equipment[i].equippedby = f;
			if(f.equipment[i].ready){
				if (f.equipment[i].x == f.equipment[i].finalpos.x && f.equipment[i].y == f.equipment[i].finalpos.y) {
					Game.equipmentplaced++;
					delay += 0.125;
				} else {
					Actuate.tween(f.equipment[i], 0.5 / BuildConfig.speed, { x: f.equipment[i].finalpos.x , y: f.equipment[i].finalpos.y })
						.delay(delay / BuildConfig.speed)
						.onComplete(function(equip:Equipment){ Game.equipmentplaced++; }, [f.equipment[i]]);
					
					if (ControlMode.showgamepadui() && f.equipment[i].x < Screen.width) {
						delay += 0.125;
					} else {
						delay += 0.25;
					}
				}
			}else{
				Game.equipmenttoplace--;
			}
		}
	}
	
	public static function endturn(f:Fighter){
		//We go through the inplay pile
		//If we've used it or it's temporary, then it's discarded
		var c:Int = 0;
		while (c < inplaypile.length){
			if (inplaypile[c].revertafterturn){
				//If something's in the *in play pile* at the end of the turn and is reverted, that
				//counts as used, and it should be discarded. If it's anywhere else, it doesn't matter
				inplaypile[c].revert();
				inplaypile[c].equipment.ready = false;
			}
			if (!inplaypile[c].equipment.ready || inplaypile[c].equipment.temporary_thisturnonly){
				inplaypile[c].equipment.dispose();
				//Do we have any temporary equipment? Scrap it.
				if (inplaypile[c].equipment.temporary_thisturnonly){
					inplaypile.splice(c, 1);
					c--;
				}else{
					discardpile.push(inplaypile.splice(c, 1)[0]);
					c--;
				}
			}
			
			c++;
		}
		
		//Just to be safe: if any temporary equipment has snuck out into the other decks, destroy it now
		//Do we have any temporary equipment? Scrap it.
		c = 0;
		while (c < discardpile.length){
			if (discardpile[c].revertafterturn) discardpile[c].revert();
			if (discardpile[c].equipment.temporary_thisturnonly){
				discardpile[c].dispose();
				discardpile.splice(c, 1);
			}else if (discardpile[c].equipment.hastag("destroy") && discardpile[c].equipment.usedthisbattle){
				discardpile[c].dispose();
				discardpile.splice(c, 1);
			}else{
				c++;
			}
		}
		
		c = 0;
		while (c < inplaypile.length){
			if (inplaypile[c].revertafterturn) inplaypile[c].revert();
			if (inplaypile[c].equipment.temporary_thisturnonly){
				inplaypile[c].dispose();
				inplaypile.splice(c, 1);
			}else if (inplaypile[c].equipment.hastag("destroy") && inplaypile[c].equipment.usedthisbattle){
				inplaypile[c].dispose();
				inplaypile.splice(c, 1);
			}else{
				c++;
			}
		}
		
		c = 0;
		while (c < drawpile.length){
			if (drawpile[c].revertafterturn) drawpile[c].revert();
			if (drawpile[c].equipment.temporary_thisturnonly){
				drawpile[c].dispose();
				drawpile.splice(c, 1);
			}else if (drawpile[c].equipment.hastag("destroy") && drawpile[c].equipment.usedthisbattle){
				drawpile[c].dispose();
				drawpile.splice(c, 1);
			}else{
				c++;
			}
		}
	}
	
	public static function endcombat(f:Fighter){
		discardallcards();
	}
	
	public static function resetfornewturn(f:Fighter){
		//New turn!
		//We go through the inplay pile, it should only contain stuff we didn't use
		//So, we push it back on the draw pile
		if (DeckPublic.deckbuilderstyle){
			//Special rule: instead of the default behavior, cards we don't play 
			//are discarded
			while (inplaypile.length > 0){
				discardpile.push(inplaypile.pop());
			}
		}else{
			while (inplaypile.length > 0){
				drawpile.push(inplaypile.pop());
			}			
		}
		
		//We destroy all the equipment cards and rebuild them
		for (i in 0 ... f.equipment.length){
			f.equipment[i].dispose();
		}
		f.equipment = [];
		
		//Next, the discard pile is added to the draw pile (if there's anything in it)
		while (discardpile.length > 0){
			drawpile.insert(0, discardpile.pop());
		}
		
		//If we're using a draw limit, reset it now.
		DeckPublic.drawnthisturn = 0;
		DeckPublic.drawlimit_bonus = 0;
	}
	
	public static function remainingcards_excludingplayed():Int{
		var inplaylength:Int = 0;
		var playedcards:Int = 0;
		for (c in inplaypile){
			if (!c.equipment.ready){
				if(!c.equipment.onscreen())	playedcards++;
			}
		}
		inplaylength = inplaypile.length - playedcards;
		
		var discardlength:Int = 0;
		for (c in discardpile){
			if (c.equipment.onceperbattle && c.equipment.usedthisbattle){
				
			}else{
				discardlength++;
			}
		}
		
		var drawpilelength:Int = 0;
		for (c in drawpile){
			if (c.equipment.onceperbattle && c.equipment.usedthisbattle){
				
			}else{
				drawpilelength++;
			}
		}
		
		var returnval:Int = inplaylength + drawpilelength + discardlength;
		
		return ((returnval > 0)?returnval:0);
	}
	
	public static function remainingcards():Int{
		return (Std.int(drawpile.length) + Std.int(discardpile.length));
	}
	
	public static function nextup(steps:Int):Card{
		if (drawpile.length - 1 - steps >= 0){
			var nextcard:Card = drawpile[drawpile.length - 1 - steps];
			if (nextcard.equipment.hastag("finale")){
				//If this discard pile isn't empty, move it to the discard pile
				if (discardpile.length > 0){
					drawpile.remove(nextcard);
					discardpile.insert(0, nextcard);
					//trace("moved finale card from drawpile to discard pile");
					return nextup(steps);
				}else if (drawpile.length > 1 && (drawpile.length - 1 - steps != 0)){
					//If we've got more cards coming, move it to the end
					drawpile.remove(nextcard);
					drawpile.insert(0, nextcard);
					//trace("moved finale card back into end of drawpile");
					return nextup(steps);
				}
			}
			return drawpile[drawpile.length - 1 - steps];
		}else if (discardpile.length - 1 - steps + drawpile.length >= 0){
			if (discardpile.length > 1){
				var nextcard:Card = discardpile[discardpile.length - 1 - steps + drawpile.length];
				if (nextcard.equipment.hastag("finale")){
					discardpile.remove(nextcard);
					discardpile.insert(0, nextcard);
					//trace("moved finale card to end of discard pile");
				}
			}
			
			return discardpile[discardpile.length - 1 - steps + drawpile.length];
		}
		return null;
	}
	
	public static function showcardslots(){
		if (!created_cardslots){
			cardslotimg = [];
			cardslotoffset = [];
			
			for(i in 0 ... DeckPublic._handsize){
				var newcardslotimg:HaxegonSprite = new HaxegonSprite(Screen.halign, Screen.valign, "ui/panels/witch/emptyslot");
				newcardslotimg.addimageframe("ui/panels/witch/upgradedslot");
				newcardslotimg.scale9grid(68, 70, 710 - 68, 453 - 70);
				newcardslotimg.width = 862 - 50;
				newcardslotimg.height = 152 * 6;
				cardslotimg.push(newcardslotimg);
				if (cardslots_midturnchangekludge){
					cardslotoffset.push(0);
				}else{
					cardslotoffset.push(Screen.width + (10 * 6));
				}
			}
			
			cardslots_midturnchangekludge = false;
			created_cardslots = true;
		}
		
		var xoffset:Float = getxoffset();
		for (i in 0 ... DeckPublic._handsize){
			cardslotimg[i].x = xoffset + (i * 160 * 6) + cardslotoffset[i] + slotpositionoffset.x;
			cardslotimg[i].y = Screen.heightmid - (cardslotimg[i].height / 2) - 2 * 6 + slotpositionoffset.y;
			cardslotimg[i].alpha = 0.25;
			cardslotimg[i].draw();
		}
	}
	
	public static function presssnapbutton(){
		var matchingcards:Array<Card> = getmatchingcards();
		
		if (DeckPublic.snapstyle == "witch"){
			//Pick a random unassigned dice
			Game.throwdice(Game.player, Game.monster);
		}else	if (DeckPublic.snapstyle == "discard"){
			AudioControl.play("jester_discard");
			//Just discard all matching cards
			//Remove the cards from play!
			for (c in 0 ... matchingcards.length){
				matchingcards[c].equipment.finalpos = new Point(matchingcards[c].equipment.x, Screen.height + 10 * 6);
				//matchingcards[c].equipment.finalpos = new Point(matchingcards[c].equipment.x, -(matchingcards[c].equipment.height * 1.5));
				matchingcards[c].equipment.ready = false;
				Actuate.tween(matchingcards[c].equipment, 0.5 / BuildConfig.speed, { x: matchingcards[c].equipment.finalpos.x , y: matchingcards[c].equipment.finalpos.y });
					//.ease(Back.easeIn);
					/*.onComplete(function(){
						if(c == 0){
							Script.actionexecute(Script.load("attack(1);"), Game.player, Game.monster, 0, [], null);
						}
					});*/
			}
			
			DeckPublic.advance(0.5 / BuildConfig.speed);
		}else	if (DeckPublic.snapstyle == "cards"){
			AudioControl.play("jester_snap");
			//Use single card behavior
			/*
			var matchingcards:Array<Card> = getmatchingcards();
			var firstcard:Card = matchingcards[0];
			
			for (c in matchingcards){
				if(c == firstcard){
					var newdicepool:Array<Dice> = [];
					var newdiceslot:Array<Int> = [];
					for(d in 0 ... c.equipment.slots.length){
						var newdice:Dice = new Dice(
							c.equipment.x + c.equipment.slotpositions[d].x + Game.dicexoffset, 
							c.equipment.y + c.equipment.slotpositions[d].y + Game.diceyoffset);
						newdice.owner = Game.player;
						if (c.equipment.slots[0] == DiceSlotType.COUNTDOWN){
							newdice.basevalue = c.equipment.remainingcountdown;
							if (newdice.basevalue > 6){
								newdice.basevalue = 6;
								c.equipment.remainingcountdown = 6;
							}
						}else{
							newdice.basevalue = Game.findoptimaldicevalueforequipment(c.equipment, c.equipment.slots[d]);
						}
						
						Game.player.dicepool.push(newdice);
						newdice.animate("snap");
						newdicepool.push(newdice);
						newdiceslot.push(d);
					}
					
					c.equipment.animate("snap");
					
					Game.delaycall(function(){
						for(d in 0 ... newdicepool.length){
							c.equipment.assigndice(newdicepool[d], newdiceslot[d]);
						}
						Combat.useequipmentifready(c.equipment, Game.player, Game.monster, 1);
					}, 0.2 / BuildConfig.speed);
				}else{
					c.equipment.ready = false;
					c.equipment.animate("disappear");
					Actuate.tween(c.equipment, 0.5 / BuildConfig.speed, {x: firstcard.equipment.x, y: firstcard.equipment.y});
				}
			}*/
		
			//DeckPublic.snap--;
			// Use *all* card behaviour
			var advancerequired:Bool = false;
			var snapscript:Bool = false;
			if (matchingcards.length > 0){
				if (matchingcards[0].equipment.scriptonsnap != ""){
					snapscript = true;
				}
				
				for (c in matchingcards){
					if(c.equipment.availablethisturn){
						if (c.equipment.shockedsetting != 0){
							c.equipment.clearshock();
						}
						
						var newdicepool:Array<Dice> = [];
						var newdiceslot:Array<Int> = [];
						for (d in 0 ... c.equipment.slots.length){
							var isfreeslot:Bool = false;
							if (c.equipment.slots[d] == DiceSlotType.FREE1 ||
								  c.equipment.slots[d] == DiceSlotType.FREE2 ||
								  c.equipment.slots[d] == DiceSlotType.FREE3 ||
								  c.equipment.slots[d] == DiceSlotType.FREE4 ||
								  c.equipment.slots[d] == DiceSlotType.FREE5 ||
								  c.equipment.slots[d] == DiceSlotType.FREE6){
								//Don't create phantom free dice on free slots
								isfreeslot = true;
							}
							if(!isfreeslot){
								var newdice:Dice = new Dice(
									c.equipment.x + c.equipment.slotpositions[d].x + Game.dicexoffset, 
									c.equipment.y + c.equipment.slotpositions[d].y + Game.diceyoffset);
								newdice.owner = Game.player;
								if (c.equipment.slots[0] == DiceSlotType.COUNTDOWN){
									newdice.basevalue = c.equipment.remainingcountdown;
									if (newdice.basevalue > 6){
										newdice.basevalue = 6;
										c.equipment.remainingcountdown = 6;
									}
								}else{
									newdice.basevalue = Game.findoptimaldicevalueforequipment(c.equipment, c.equipment.slots[d])[0];
								}
								
								Game.player.dicepool.push(newdice);
								newdice.animate("snap");
								newdicepool.push(newdice);
								newdiceslot.push(d);
							}
						}
						
						c.equipment.animate("snap");
						
						Game.delaycall(function(){
							for(d in 0 ... newdicepool.length){
								c.equipment.assigndice(newdicepool[d], newdiceslot[d]);
							}
							Combat.useequipmentifready(c.equipment, Game.player, Game.monster, 1, false);
						}, 0.2 / BuildConfig.speed);
						
						if (snapscript){
							//Important that this doesn't happen until *after* the equipment scripts above get
							//executed, or these card's snap effect could happen in the wrong order
							Game.delaycall(function(){
								Script.rungamescript(c.equipment.scriptonsnap, "snap_" + matchingcards.length, Game.player, c.equipment);
							}, (0.2 / BuildConfig.speed) + (0.6 / (BuildConfig.speed * Settings.animationspeed)));
							snapscript = false;
						}
					}else{
						//If the card is unavailable, just discard it
						advancerequired = true;
						c.equipment.finalpos = new Point(c.equipment.x, Screen.height + 10 * 6);
						c.equipment.ready = false;
						Actuate.tween(c.equipment, 0.5 / BuildConfig.speed, { x: c.equipment.finalpos.x , y: c.equipment.finalpos.y });
					}
				}
			}
			
			if(advancerequired){
				DeckPublic.advance(0.5 / BuildConfig.speed);
			}
		}else if (DeckPublic.snapstyle == "dice"){
			AudioControl.play("jester_snap");
			//Old removing cards and give dice behaviour
			//Remove the cards from play!
			for (c in matchingcards){
				c.equipment.finalpos = new Point(c.equipment.x, Screen.height + 10 * 6);
				c.equipment.ready = false;
				Actuate.tween(c.equipment, 0.5 / BuildConfig.speed, { x: c.equipment.finalpos.x , y: c.equipment.finalpos.y });
			}
			
			//Give you some bonus dice!
			Game.delaycall(function(){
				var newdice:Array<Dice> = Game.player.rolldice(matchingcards.length - 1, Gfx.BOTTOM);
				
				//Check for counterspell
				Game.player.checkfordicecounter(newdice);
				//run onrolldice script hooks
				Game.player.runonrolldicescripts(newdice);
			}, 0.5 / BuildConfig.speed);
			//Draw more cards
			DeckPublic.advance(0.5 / BuildConfig.speed);
		}
	}
	
	public static function punchlinecard():Bool{
		var remainingreadycards:Int = 0;
		for (c in inplaypile){
			if (c.equipment.ready){
				remainingreadycards++;
			}
		}
		
		if (remainingreadycards <= 0) return true;
		return false;
	}
	
	public static function discardhand(){
		//Remove the cards from play!
		for (c in inplaypile){
			if(c.equipment.ready){
				c.equipment.finalpos = new Point(c.equipment.x, Screen.height + 10 * 6);
				c.equipment.ready = false;
				Actuate.tween(c.equipment, 0.5 / BuildConfig.speed, { x: c.equipment.finalpos.x , y: c.equipment.finalpos.y });
			}
		}
		
		DeckPublic.advance(0.5 / BuildConfig.speed);
	}
	
	public static function match3(f:Fighter){
		//Return second and third cards to deck
		var cardnum:Int = 0;
		var copycard:Card = null;
		for (i in 0 ... inplaypile.length){
			//final pos is where the panel sits once it's placed
			if (inplaypile[i].equipment.ready){
				if (cardnum == 0){
					copycard = inplaypile[i];
				}else	if (cardnum > 0){
					inplaypile[i].equipment.finalpos = new Point(Screen.width + (10 * 6), inplaypile[i].equipment.y);				
					Actuate.tween(inplaypile[i].equipment, 0.5 / BuildConfig.speed, { x: inplaypile[i].equipment.finalpos.x })
						.delay((2 - cardnum) * 0.25 / BuildConfig.speed)
						.onComplete(function(c:Card){
							inplaypile.remove(c);
							drawpile.push(c);
						}, [inplaypile[i]]);
				}
				cardnum++;
			}
		}
		
		//Make duplicate cards!
		copycard.equipment.animate("flash");
		
		//Game.delaycall(function(){
			//Draw more cards
			var xoffset:Float = getxoffset();
			for (i in 0 ... 2){
				var duplicatecard:Card = new Card(copycard.equipment.copy());
				duplicatecard.equipment.temporary_thisturnonly = true;
				
				inplaypile.push(duplicatecard);
				f.equipment.push(duplicatecard.equipment);
				//initial pos is where the panel exists offscreen. We want all cards to start offscreen to the right
				duplicatecard.equipment.initialpos = new Point(copycard.equipment.x, copycard.equipment.y);
				duplicatecard.equipment.finalpos = new Point(xoffset + ((i + 1) * 160 * 6), Screen.heightmid - (copycard.equipment.height / 2));
				duplicatecard.equipment.x = duplicatecard.equipment.initialpos.x;
				duplicatecard.equipment.y = duplicatecard.equipment.initialpos.y;
				duplicatecard.equipment.equipalpha = 0;
				duplicatecard.equipment.displaycolumn = duplicatecard.equipment.column = (i + 1);
				
				Actuate.tween(duplicatecard.equipment, 0.5 / BuildConfig.speed, {
					x: duplicatecard.equipment.finalpos.x, 
					y: duplicatecard.equipment.finalpos.y,
					equipalpha: 1.0
				});//.delay(i * 0.25 / BuildConfig.speed);
			}
		//}, 0.25 / BuildConfig.speed);
	}
	
	public static function match2(f:Fighter){
		copynextcard(f, null);
	}
	
	/* For the Inventor backup card - if e is null, then copy the first card */
	public static function copynextcard(f:Fighter, e:Equipment){
		//Ok, first, we identify this card
		var inventorcard:Card = null;
		var inventorcardindex:Int = -1;
		if (e == null){
			inventorcardindex = 0;
		}else{
			for (i in 0 ... inplaypile.length){
				if (inplaypile[i].equipment == e){
					inventorcard = inplaypile[i];
					inventorcardindex = i;
				}
			}
		}
		
		//Next, we idenfity the NEXT card
		var nextcard:Card = null;
		var nextcardindex:Int = -1;
		var seeninventorcard:Bool = false;
		if (e == null){
			seeninventorcard = true;
		}
		for (i in 0 ... inplaypile.length){
			if (seeninventorcard){
				if(nextcard == null){
					if (inplaypile[i].equipment.ready){
						nextcard = inplaypile[i];
						nextcardindex = i;
					}
				}
			}
			
			if (inplaypile[i] == inventorcard){
				seeninventorcard = true;
			}
		}
		
		if (nextcard == null){
			if (drawpile.length > 0){
				//Edge case! The next card is on the top of the deck. So, let's just duplicate that!
				nextcard = drawpile[drawpile.length - 1];
				var duplicatecard:Card = new Card(nextcard.equipment.copy());
				if (duplicatecard.equipment.hastag("finale")){
					duplicatecard.equipment.removetag("finale");
				}
				drawpile.push(duplicatecard);
				duplicatecard.equipment.temporary_thisturnonly = true;
				Combat.gamepad_selectedequipment = duplicatecard.equipment;
			}else{
				//Edge case! There is NOTHING to copy. Quit out now.
			}
		}else{
			var duplicatecard:Card = new Card(nextcard.equipment.copy());
			duplicatecard.equipment.temporary_thisturnonly = true;
			inplaypile.insert(inventorcardindex, duplicatecard);
			Combat.gamepad_selectedequipment = duplicatecard.equipment;
		}
		
		//Remove the inventor card from play!
		if(e != null){
			inventorcard.equipment.finalpos = new Point(inventorcard.equipment.x, Screen.height + 10 * 6);
			inventorcard.equipment.ready = false;
			Actuate.tween(inventorcard.equipment, 0.5 / BuildConfig.speed, { x: inventorcard.equipment.finalpos.x , y: inventorcard.equipment.finalpos.y });
		}
		
		//If there are more than three cards in play, push the excess cards back onto the deck
		//Return second and third cards to deck
		var cardnum:Int = 0;
		for (i in 0 ... inplaypile.length){
			//final pos is where the panel sits once it's placed
			if (inplaypile[i].equipment.ready){
				if (cardnum >= 3){
					inplaypile[i].equipment.finalpos = new Point(Screen.width + (10 * 6), inplaypile[i].equipment.y);
					Actuate.tween(inplaypile[i].equipment, 0.5 / BuildConfig.speed, { x: inplaypile[i].equipment.finalpos.x })
						.delay((2 - cardnum) * 0.25 / BuildConfig.speed)
						.onComplete(function(c:Card){
							inplaypile.remove(c);
							drawpile.push(c);
						}, [inplaypile[i]]);
				}
				cardnum++;
			}
		}
		
		DeckPublic.advance(0.5 / BuildConfig.speed);
	}
	
	/* True if there are at least two cards matching */
	public static function matchingcards():Bool{
		var matchingcardsresult:Array<Card> = getmatchingcards();
		if (matchingcardsresult.length >= 2) return true;
		return false;
	}
	
	public static function getmatchingcards():Array<Card>{
		// Check for three of a kind
		for (c1 in inplaypile){
			for (c2 in inplaypile){
				for (c3 in inplaypile){
					if (c1 != c2 && c1 != c3 && c2 != c3){
						if (c1.equipment.ready && c2.equipment.ready && c3.equipment.ready){
							if (!c1.equipment.availablethisturn && !c2.equipment.availablethisturn && !c3.equipment.availablethisturn){
								//Unavailable cards match with each other!
								return [c1, c2, c3];
							}
							if (c1.equipment.name == c2.equipment.name && c1.equipment.name == c3.equipment.name){
								//Available cards match if they all have the same name
								if (c1.equipment.availablethisturn && c2.equipment.availablethisturn && c3.equipment.availablethisturn){
									return [c1, c2, c3];
								}
							}
						}
					}
				}
			}
		}
		
		// Check for pairs
		for (c1 in inplaypile){
			for (c2 in inplaypile){
				if(c1 != c2){
					if (c1.equipment.ready){
						if (c2.equipment.ready){
							if (!c1.equipment.availablethisturn){
								if (!c2.equipment.availablethisturn){
									//Unavailable cards match with each other!
									return [c1, c2];
								}
							}
							if (c1.equipment.name == c2.equipment.name){
								//Available cards match if they all have the same name
								if (c1.equipment.availablethisturn && c2.equipment.availablethisturn){
									return [c1, c2];
								}
							}
						}
					}
				}
			}
		}
		
		return [];
	}
	
	public static var skillcard:Equipment;
	public static var cardslotimg:Array<HaxegonSprite>;
	public static var cardslotoffset:Array<Float>;
	public static var created_cardslots:Bool;
	public static var cardslots_midturnchangekludge:Bool;
	
	public static var drawpile:Array<Card>;
	public static var inplaypile:Array<Card>;
	public static var discardpile:Array<Card>;
	
	public static var mastercardnamelist:Array<String>;
	public static var mastercardlist:Array<Card>;
	public static var mastercardlistscrollbar:Float;

	public static var slotpositionoffset:Point;
}