import haxegon.*;
import elements.*;
import states.*;

/* Warning: this class is fully accessible from scripting. 
 * Take care not to expose anything dangerous. */
class Rules{
  public static function reset(){
		Dungeon.locationarrow = false;
		Dungeon.locationarrow_delay = 0;
		
		Reunion.draftmode = false;
		Reunion.dicesupressed = false;
		
		hasinventoryaccess = true;
		upgradeplayerequipment = false;
		upgradeenemyequipment = false;
    enemyhpadjust = 1.0;
		enemiescanthrowdice = false;
		hpchangeonlevelup = 4;
		mimiccurse = false;
		bigequipmentmode = false;
		includerareenemies = true;
		lowhpmusic = true;
		manualequipmentfiring = false;
		reunionwarrior_rerollcount = 0;
		reunionwarrior_workoutrewards = [];
		disablerelaxedmode = false;
		
		burningdicecost = 2;
		alternateshockcost = 3;
		shocktype = "";
		limitbreakcost = 0;
		bonusdamage = 0;
		
		movelimit = 0;
		movelimit_current = 0;
		
		ignitedice = false;
		igniterange = [];
		
		playerinnatestat = [];
		playerinnatestatamount = [];
		playerinnatestat_firstturnonly = [];
		
		enemyinnatestat = [];
		enemyinnatestatamount = [];
		enemyinnatestat_firstturnonly = [];
		
		excludedenemies = [];
		#if (rata || switch || ios || android)
			//For now, just remove Copycat from the game completely on all non-desktop
			//platforms - they cause crash bugs that are too difficult to fix.
			excludedenemies = ["Copycat"];
		#end
		includedenemies = [];
		
		overworldbutton_name = "";
		overworldbutton_action = "";
		
		jackpotsubstitutecard = "";
		
		enemycountdownrate = 1;
		
		overload = false;
		
		expenabled = true;
		disableflee = false;
		
		resetreplacementgfx();
		reunioncoinmode = false;
		
		Game.rules_stackplayerdice = false;
		Game.rules_stackplayerdice_resetsequence = false;
		Game.rules_stackplayerdice_loopsequence = true;
		Game.rules_stackplayerdice_looponce = true;
		_stackplayerdice = [];
		
		Game.rules_stackenemydice = false;
		Game.rules_stackenemydice_resetsequence = false;
		Game.rules_stackenemydice_loopsequence = true;
		Game.rules_stackenemydice_looponce = false;
		_stackenemydice = [];
		
		modifyplayerdicerange = false;
		modifyenemydicerange = false;
		actualenemydicerange = [];
		actualplayerdicerange = [];
		
		doublechests = false;
		
		curseodds = 50;
		alternatedodgeodds = 50;
		alternatestatus = [];
		//setalternate("all");
		
		monstermode = false;
		Monstermode.selectedplayer = null;
		equipmentrechargesbetweenturns = true;
		
		levelup_giveleveluprewards = true;
		
		robot_startingcpu = 9;
		robot_nogoingback = false;
		robot_requestodds = 100;
		robot_errorpenalty = 0;
		jackpotskills = [];
		jackpotskills_lowodds = [];
		
		inventor_inspiration = true;
		inventor_blindinspiration = false;
		_inventor_gadgets = 1;
		inventor_equipmentrust = 0;
		
		playerpoisondelta = -1;
		enemypoisondelta = -1;
		
		witch_randomspellslot = [[], [], [], []];
		
		substitutions = null;
		
		superenemieslevel2 = 0;
		superenemieslevel3 = 0;
		superenemieslevel4 = 0;
		superenemieslevel5 = 0;
		
		extrascript_startcombat = [];
	  extrascript_aftercombat = [];
	  extrascript_beforestartturn = [];
	  extrascript_onstartturn = [];
	  extrascript_endturn = [];
		extrascript_playerequipmentuse = [];
		extrascript_enemyequipmentuse = [];
		
		enemyequipmentchanges = new Map<String, Array<String>>();
		enemydicechanges = new Map<String, Int>();
		enemyhpchanges = new Map<String, Int>();
		enemyinnatechanges = new Map<String, Array<String>>();
		enemylevelchanges = new Map<String, Int>();
		
		remix = false;
		altequipmentname = "Equipment?";
		Remixstate.resetfornewrun();
  }
	
	public static function checkgfxreplace(gfx:String):String{
		if (replacementgfx == null){
			replacementgfx = new Map<String, String>();
		}
		
		if (replacementgfx.exists(gfx)){
			return replacementgfx.get(gfx);
		}
		
		return gfx;
	}
	
	public static function replacegfx(sourcegfx:String, newgfx:String){
		if (replacementgfx == null){
			replacementgfx = new Map<String, String>();
		}
		
		replacementgfx.set(sourcegfx, newgfx);
	}
	
	public static function resetreplacementgfx(){
		replacementgfx = new Map<String, String>();
	}
	
	public static function changeenemyequipment(enemy:String, newequipment:Array<String>){
		enemyequipmentchanges.set(enemy, newequipment);
	}
	
	public static function changeenemydice(enemy:String, newdice:Int){
		enemydicechanges.set(enemy, newdice);
	}
	
	public static function changeenemyhp(enemy:String, newhp:Int){
		enemyhpchanges.set(enemy, newhp);
	}
	
	public static function changeenemylevel(enemy:String, newlevel:Int){
		enemylevelchanges.set(enemy, newlevel);
	}
	
	public static function changeenemyinnate(enemy:String, newinnates:Array<String>){
		enemyinnatechanges.set(enemy, newinnates);
	}
	
	public static function excludeenemies(_enemylist:Array<String>){
		excludedenemies = _enemylist;
		#if (rata || switch || ios || android)
			//For now, just remove Copycat from the game completely on all non-desktop
			//platforms - they cause crash bugs that are too difficult to fix.
			if (excludedenemies != null){
				if (excludedenemies.indexOf("Copycat") == -1){
					excludedenemies.push("Copycat");
				}
			}
		#end
	}
	
	public static function includeenemies(_enemylist:Array<String>){
		includedenemies = _enemylist;
	}
	
	/* A midgame switch to finders keepers for remix mode */
	public static function switchtofinderskeepers(){
		//This requires the following changes:
	  // - Change the Thief skill card to Finders Keepers
		// - Remove all treasure chests from the Dungeon
		var skillcard:Equipment = Game.player.getskillcard();
		Game.player.equipment.remove(skillcard);
		skillcard.dispose();
		Game.player.hasstolencard = false;
		
		Game.player.equipment.push(Game.player.createskillcard("Finders Keepers", []));
		
		//Remove all treasure from the dungeon!
		//If we've already generated the dungeon, then this function should update it
		if (Dungeon.floor != null){
			if (Dungeon.floor.length > 0){
				for (fl in Dungeon.floor){
					for (n in fl.nodes){
						if (n.type == DungeonBlockType.ITEM){
							if (n.item.toLowerCase() != "Wooden Stake".toLowerCase()){
								//Remove every chest *except* the wooden stake
								n.item = "";
								fl.clearnode(n);
							}
						}
					}
				}
			}
		}
	}
	
	/* Change all the shops to contain any item from the game */
	public static function mixedupshops(){
		var equiplist:Array<String> = Game.getequipmentlist(null, [], ['skillcard', 'excludefromrandomlists', 'robotonly', 'witchonly']);
		equiplist = Random.shuffle(equiplist);
		
		if (Dungeon.floor != null){
			if (Dungeon.floor.length > 0){
				for (fl in Dungeon.floor){
					for (n in fl.nodes){
						if (n.type == DungeonBlockType.SHOP){
							var shop:Shop = fl.getshop(n);
							for (i in 0 ... shop.contents.length){
								if (shop.contents[i].type.toLowerCase() == "equipment"){
									var level:Int = shop.contents[i].level;
									var rewardname:String = equiplist.pop();
									shop.contents[i].dispose();
									shop.contents[i] = new LevelUpReward("equipment", level, rewardname, false);
								}
							}
						}
					}
				}
			}
		}
	}
	
	/* A midgame switch to it'll be fine for remix mode */
	public static function switchtoitllbefine(){
		upgradeplayerequipment = true;
		
		substitute("upgrade", "copyshop");
		
		//Add a plus to all the equipment levelup rewards
		for(i in 0 ... LevelUpScreen.leveluprewards.length){
			if (LevelUpScreen.leveluprewards[i].type.toLowerCase() == "equipment"){
				if (S.right(LevelUpScreen.leveluprewards[i].rewardname, 1) != "+"){
					var level:Int = LevelUpScreen.leveluprewards[i].level;
					var rewardname:String = LevelUpScreen.leveluprewards[i].rewardname + "+";
					LevelUpScreen.leveluprewards[i].dispose();
					LevelUpScreen.leveluprewards[i] = new LevelUpReward("equipment", level, rewardname, false);
				}
			}
		}
	}
	
	public static function addsuperenemies(num:Int){
		var enemylist:Array<String> = Game.getenemylistindungeon();
		
		if (num == 2){
			//Exchange a floor 2 and floor 3 enemy with super enemies
			//Get a suitable level 1 enemy:
			var level1enemy:Array<String> = [];
			for (e in Gamedata.fightertemplates){
				if (e.level == 1 && e.hassuper){
					if(enemylist.indexOf(e.name) == -1){
						level1enemy.push(e.name);
					}
				}
			}
			var placedlevel1:Bool = false;
			
			var level2enemy:Array<String> = [];
			for (e in Gamedata.fightertemplates){
				if (e.level == 2 && e.hassuper){
					if(enemylist.indexOf(e.name) == -1){
						level2enemy.push(e.name);
					}
				}
			}
			var placedlevel2:Bool = false;
			
			if (Dungeon.floor != null){
				if (Dungeon.floor.length > 0){
					for (fl in Dungeon.floor){
						for (n in fl.nodes){
							if (n.type == DungeonBlockType.ENEMY){
								if(n.enemytemplate.level == 2 && !placedlevel1){
									fl.updatenodedata(n, GraphNodeData.createenemy("Super " + Random.pick(level1enemy)));
									placedlevel1 = true;
								}
								if(n.enemytemplate.level == 3 && !placedlevel2){
									fl.updatenodedata(n, GraphNodeData.createenemy("Super " + Random.pick(level2enemy)));
									placedlevel2 = true;
								}
							}
						}
					}
				}
			}
		}else{
			throw("Error: Rules.addsuperenemies() is only implemented for 2 right now");
		}
	}
	
	public static function makeallequipmentbig(){
		//Remove *all* the player's equipment, and reequip it
		var equipmentlist:Array<Equipment> = [];
		for (item in Inventory.equipmentslots.getlist()){
			equipmentlist.push(item);
		}
		for (item in Inventory.backpack.getlist()){
			equipmentlist.push(item);
		}
		
		Inventory.equipmentslots.empty_and_dispose_collectibles_only();
		Inventory.backpack.empty_and_dispose_collectibles_only();
		
		for (e in equipmentlist){
			Game.smartgiveequipmenttoplayer(e, false);
		}
		
		bigequipmentmode = true;
		
		//Flush all the equipment levelup rewards (i.e. regenerate the equipment)
		for(i in 0 ... LevelUpScreen.leveluprewards.length){
			if (LevelUpScreen.leveluprewards[i].type.toLowerCase() == "equipment"){
				var level:Int = LevelUpScreen.leveluprewards[i].level;
				var rewardname:String = LevelUpScreen.leveluprewards[i].rewardname + "+";
				LevelUpScreen.leveluprewards[i].dispose();
				LevelUpScreen.leveluprewards[i] = new LevelUpReward("equipment", level, rewardname, false);
			}
		}
		
		//Flush all the shop rewards too
		if (Dungeon.floor != null){
			if (Dungeon.floor.length > 0){
				for (fl in Dungeon.floor){
					for (n in fl.nodes){
						if (n.type == DungeonBlockType.SHOP){
							var shop:Shop = fl.getshop(n);
							for (i in 0 ... shop.contents.length){
								if (shop.contents[i].type.toLowerCase() == "equipment"){
									var level:Int = shop.contents[i].level;
									var rewardname:String = shop.contents[i].rewardname + "+";
									shop.contents[i].dispose();
									shop.contents[i] = new LevelUpReward("equipment", level, rewardname, false);
								}
							}
						}
					}
				}
			}
		}
	}
	
	public static function setalternate(stat:String){
		alternatestatus.push(stat);
	}
	
	public static function clearalternate(stat:String){
		if (alternatestatus != null){
			if(alternatestatus.length > 0){
				if (alternatestatus.indexOf(stat) > -1){
					alternatestatus.remove(stat);
				}
			}
		}
	}
	
	public static function hasalternate(stat:String):Bool{
		//Check both: we've set this stat to have an alternate, and it's available
		if (alternatestatus == null) return false;
		
		if (alternatestatus.indexOf(stat) > -1 || alternatestatus.indexOf("all") > -1){
			if (Gamedata.getstatustemplate("alternate_" + stat) != null){
				return true;
			}
		}
		return false;
	}
	
	public static function addextrascript(s:String, when:String){
		if (when == "startcombat"){
			extrascript_startcombat.push(s);
		}else if (when == "aftercombat"){
			extrascript_aftercombat.push(s);
		}else if (when == "beforestartturn"){
			extrascript_beforestartturn.push(s);
		}else if (when == "onstartturn"){
			extrascript_onstartturn.push(s);
		}else if (when == "endturn"){
			extrascript_endturn.push(s);
		}else if (when == "playerequipmentuse"){
			extrascript_playerequipmentuse.push(s);
		}else if (when == "enemyequipmentuse"){
			extrascript_enemyequipmentuse.push(s);
		}else{
			throw("Error: Cannot append script \"" + s + "\" to \"" + when + "\" - not a valid script point.\n"
			+" (valid: startcombat, aftercombat, beforestartturn, onstartturn, endturn, playerequipmentuse, enemyequipmentuse)");
		}
	}
	
	public static function inventor_setgadgets(num:Int){
		if(num != _inventor_gadgets){
			_inventor_gadgets = num;
			
			var gadget:Equipment = Game.player.getskillcard();
			var inventorskills:Array<String> = Episodestate.activeepisode.fightertemplate.skills;
			
			for (i in 1 ... inventorskills.length){
				var gadgetindex:Int = i - 1;
				if (gadgetindex < gadget.skills.length){
					gadget.skills[gadgetindex].dispose();
					gadget.skills[gadgetindex] = new Skill(inventorskills[i], 22 + (i * 40));
				}else{
					gadget.skills.push(new Skill(inventorskills[i], 22 + (i * 40)));
				}
				
				if (gadgetindex < gadget.skillsavailable.length){
					gadget.skillsavailable[gadgetindex] = true;
					gadget.skills_temporarythisfight[gadgetindex] = false;
				}else{
					gadget.skillsavailable.push(true);
					gadget.skills_temporarythisfight.push(false);
				}
			}
			
			gadget.height = (135 - 57 + 45) * 6;
			if (inventorskills.length > 2){
				gadget.height += 260 * (inventorskills.length - 3);
			}
		}
	}
	
	//Like substitute, but both directions
	public static function swap(equip1:String, equip2:String, force:Bool = false){
		trace("swapping " + equip1 + " with " + equip2);
		if (substitutions == null){
			substitutions = new Map<String, String>();
		}
		
		substitutions.set(equip1, equip2);
		substitutions.set(equip2, equip1);
		
		//If we've already generated the dungeon, then this function should update it
		//This is the same as below, but it checks both directions
		if (Dungeon.floor != null){
			if (Dungeon.floor.length > 0){
				for (fl in Dungeon.floor){
					for (n in fl.nodes){
						if (n.type == DungeonBlockType.SHOP){
							if (!n.visited || force){
								var nodeshop:Shop = fl.getshop(n);
								if(nodeshop != null){
									for (i in 0 ... nodeshop.contents.length){
										if (nodeshop.contents[i].type == "equipment"){
											if (nodeshop.contents[i].rewardname == equip1){
												//trace("found a shop selling " + equip1 + ", substituting " + equip2);
												nodeshop.contents[i].refresh();
											}else if (nodeshop.contents[i].rewardname == equip2){
												//trace("found a shop selling " + equip2 + ", substituting " + equip1);
												nodeshop.contents[i].refresh();
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
		
		//Do a quick refresh of stuff we've got equipped to ensure that gets updated
		Inventory.reset();
		Inventory.reequipplayer();
		
		//Refresh the level up rewards, just in case anything's changed
		if(LevelUpScreen.leveluprewards != null){
			for (r in LevelUpScreen.leveluprewards)	r.refresh();
		}
	}
	
	public static function substitute(equip1:String, equip2:String, force:Bool = false){
		if (substitutions == null){
			substitutions = new Map<String, String>();
		}
		
		//trace("substituting " + equip1 + " for " + equip2);
		substitutions.set(equip1, equip2);
		
		//If we've already generated the dungeon, then this function should update it
		if (Dungeon.floor != null){
			if (Dungeon.floor.length > 0){
				for (fl in Dungeon.floor){
					for (n in fl.nodes){
						if (n.type == DungeonBlockType.BOOSTERPACK){
							//trace(n.item);
							if (!n.visited || force){
								if (n.item == equip1){
									n.item = equip2;
									if (equip2 == "")	fl.clearnode(n);
								}
							}else{
								//trace("not substituting because we've already visited this node");
							}
						}else if (n.type == DungeonBlockType.ITEM){
							//trace(n.item);
							if (!n.visited || force){
								if (n.item == equip1 && equip2 == ""){
									fl.clearnode(n);
								}
							}else{
								//trace("not substituting because we've already visited this node");
							}
						}else if (n.type == DungeonBlockType.SHOP){
							if (!n.visited || force){
								var nodeshop:Shop = fl.getshop(n);
								if(nodeshop != null){
									for (i in 0 ... nodeshop.contents.length){
										if (nodeshop.contents[i].type == "equipment"){
											if (nodeshop.contents[i].rewardname == equip1){
												//trace("found a shop selling " + equip1 + ", substituting " + equip2);
												var oldcost:Int = nodeshop.contents[i].level;
												nodeshop.contents[i].dispose();
												nodeshop.contents[i] = new LevelUpReward("equipment", oldcost, equip2);
											}
										}
									}
								}
							}
						}else if (n.type == DungeonBlockType.ENEMY){
							if (n.enemytemplate != null){
								if (n.enemytemplate.name == equip1){
									fl.updatenodedata(n, GraphNodeData.createenemy(equip2));
								}
							}
						}else if (equip1 == "upgrade" && n.type == DungeonBlockType.UPGRADE){
							fl.updatenodedata(n, GraphNodeData.createcopyshop());
						}
					}
				}
			}
		}
		
		//Do a quick refresh of stuff we've got equipped to ensure that gets updated
		Inventory.reset();
		Inventory.reequipplayer();
		
		//Refresh the level up rewards, just in case anything's changed
		if(LevelUpScreen.leveluprewards != null){
			for (r in LevelUpScreen.leveluprewards)	r.refresh();
		}
	}
	
	public static function addplayerinnatestatus(stat:String, ?amount:Int = 1, ?firstturnonly:Bool = false){
		playerinnatestat.push(stat);
		playerinnatestatamount.push(amount);
		playerinnatestat_firstturnonly.push(firstturnonly);
	}
	
	public static function addenemyinnatestatus(stat:String, ?amount:Int = 1, ?firstturnonly:Bool = false){
		enemyinnatestat.push(stat);
		enemyinnatestatamount.push(amount);
		enemyinnatestat_firstturnonly.push(firstturnonly);
	}
  
	public static var playerpoisondelta:Int;
	public static var enemypoisondelta:Int;
	
	public static var upgradeplayerequipment:Bool;
	public static var upgradeenemyequipment:Bool;
  public static var enemyhpadjust:Float;
	public static var enemiescanthrowdice:Bool;
	public static var hpchangeonlevelup:Int;
	public static var playerinnatestat:Array<String>;
	public static var playerinnatestatamount:Array<Int>;
	public static var playerinnatestat_firstturnonly:Array<Bool>;
	public static var enemyinnatestat:Array<String>;
	public static var enemyinnatestatamount:Array<Int>;
	public static var enemyinnatestat_firstturnonly:Array<Bool>;
	
	public static function stackplayerdice(stack:Array<Array<Int>>, _resetsequenceonnewturn:Bool, _loopsequence:Bool = true, _looponce:Bool = false){
		Game.rules_stackplayerdice_index = 0;
		if (stack.length == 0){
			Game.rules_stackplayerdice = false;
			_stackplayerdice = [];
			Game.rules_stackplayerdice_resetsequence = false;
			Game.rules_stackplayerdice_loopsequence = false;
			Game.rules_stackplayerdice_looponce = false;
		}else{
			Game.rules_stackplayerdice = true;
			_stackplayerdice = stack;
			Game.rules_stackplayerdice_resetsequence = _resetsequenceonnewturn;
			Game.rules_stackplayerdice_loopsequence = _loopsequence;
			Game.rules_stackplayerdice_looponce = _looponce;
		}
	}
	public static var _stackplayerdice:Array<Array<Int>>;
	
	public static function stackenemydice(stack:Array<Array<Int>>, _resetsequenceonnewturn:Bool, _loopsequence:Bool = true, _looponce:Bool = false){
		Game.rules_stackenemydice = true;
		_stackenemydice = stack;
		Game.rules_stackenemydice_resetsequence = _resetsequenceonnewturn;
		Game.rules_stackenemydice_loopsequence = _loopsequence;
		Game.rules_stackenemydice_looponce = _looponce;
	}
	public static var _stackenemydice:Array<Array<Int>>;

	public static var burningdicecost:Int;
	public static var alternateshockcost:Int;
	public static var shocktype:String;
	public static var mimiccurse:Bool;
	public static var monstermode:Bool;
	public static var robot_startingcpu:Int;
	public static var robot_nogoingback:Bool;
	public static var robot_requestodds:Int;
	public static var robot_errorpenalty:Int;
	public static var jackpotsubstitutecard:String;
	public static var witch_randomspellslot:Array<Array<String>>;
	public static var inventor_inspiration:Bool;
	public static var inventor_blindinspiration:Bool;
	public static var _inventor_gadgets:Int;
	public static var inventor_equipmentrust:Int;
	public static var levelup_giveleveluprewards:Bool;
	public static var bonusdamage:Int;
	public static var ignitedice:Bool;
	public static var igniterange:Array<Int>;
	
	public static var limitbreakcost:Int;
	
	public static var equipmentrechargesbetweenturns:Bool;
	
	public static var superenemieslevel2:Int;
	public static var superenemieslevel3:Int;
	public static var superenemieslevel4:Int;
	public static var superenemieslevel5:Int;
	
	public static var doublechests:Bool;
	
	public static var remix:Bool;
	
	public static var curseodds:Int;
	public static var alternatedodgeodds:Int;
	public static var bigequipmentmode:Bool;
	public static var lowhpmusic:Bool;
	public static var disableflee:Bool;
	
	public static var movelimit:Int;
	public static var movelimit_current:Int;
	
	public static var enemycountdownrate:Float;
	
	public static var includerareenemies:Bool;
	
	public static var substitutions:Map<String, String>;
	public static var excludedenemies:Array<String>;
	public static var includedenemies:Array<String>;
	
	public static var enemyequipmentchanges:Map<String, Array<String>>;
	public static var enemydicechanges:Map<String, Int>;
	public static var enemyhpchanges:Map<String, Int>;
	public static var enemyinnatechanges:Map<String, Array<String>>;
	public static var enemylevelchanges:Map<String, Int>;
	
	public static var extrascript_startcombat:Array<String>;
	public static var extrascript_aftercombat:Array<String>;
	public static var extrascript_beforestartturn:Array<String>;
	public static var extrascript_onstartturn:Array<String>;
	public static var extrascript_endturn:Array<String>;
	public static var extrascript_playerequipmentuse:Array<String>;
	public static var extrascript_enemyequipmentuse:Array<String>;
	
	public static var alternatestatus:Array<String>;
	
	public static var overworldbutton_name:String;
	public static var overworldbutton_action:String;
	public static var rulescreen_text:Array<String>;
	
	public static var hasinventoryaccess:Bool;
	
	public static function rulescreen(file:String){
		overworldbutton_name = "Rules";
		overworldbutton_action = "rulescreen";
		
		rulescreen_text = Data.loadtext(file);
	}
	
	public static var jackpotskills:Array<String>;
	public static var jackpotskills_lowodds:Array<String>;
	
	public static function enemydicerange(_range:Array<Int>){
		modifyenemydicerange = true;
		actualenemydicerange = _range;
	}
	
	public static function playerdicerange(_range:Array<Int>){
		modifyplayerdicerange = true;
		actualplayerdicerange = _range;
	}
	
	public static var modifyenemydicerange:Bool;
	public static var actualenemydicerange:Array<Int>;
	public static var modifyplayerdicerange:Bool;
	public static var actualplayerdicerange:Array<Int>;
	
	public static function enableexp(){
		expenabled = true;
	}
	
	public static function disableexp(){
		expenabled = false;
	}
	
	public static var expenabled:Bool;
	public static var overload:Bool;
	
	public static var replacementgfx:Map<String, String>;
	public static var reunioncoinmode:Bool;
	
	public static function startdraftmode(cardlist:Array<String>, headertext:String, duringcombat:Bool){
		//Forward this directly to...
		Reunion.startdraftmode(cardlist, headertext, duringcombat);
	}
	
	public static function reunionwarriormode(_rerollcount:Int, _cards:Array<String>){
		reunionwarrior_rerollcount = _rerollcount;
		for (c in _cards){
			Reunion.warriorcard_addworkout(c);
		}
		
		overworldbutton_name = "Workouts";
		overworldbutton_action = "trainingcards";
	}
	
	//I know, it's horrible, but it's not worth doing this properly right now
	public static function reunionwarriorcommand(cmd:String):Dynamic{
		if (cmd == "getcurrentcard"){
			return Reunion.warriorcard_currentcard;
		}else if (cmd == "isused"){
			return Reunion.warriorcard_used;
		}else if (cmd == "sort"){
			ViewTraining.sortcards();
			return null;
		}else if (cmd == "rerollincrease"){
			Reunion.warriorcard_numrerolls++;
		}else if (cmd == "fixturncount"){
			Combat.turncount--;
		}else if (cmd == "omnislash"){
			Reunion.warriorcard_addworkout("Omnislash[]");
		}
		return null;
	}
	
	public static var disablerelaxedmode:Bool;
	
	public static var manualequipmentfiring:Bool;
	public static var reunionwarrior_rerollcount:Int;
	public static var reunionwarrior_workoutrewards:Array<Array<String>>;
	public static var altequipmentname:String;
}