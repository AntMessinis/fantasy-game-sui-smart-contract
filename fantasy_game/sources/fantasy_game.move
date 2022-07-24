module fantasy_game::fantasy_game {
    use sui::object::{Self, ID, Info};
    use sui::transfer;
    use sui::utf8::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use std::option::{Self, Option};
    use sui::math;


    // DM has ownership of the fantasy_game and is the one 
    // who fills the dungeon with enemies 
    struct DungeonMaster has key{
        info: Info,
        game_id: ID
    }

    struct GameInfo has key {
        info: Info,
        admin: address
    }

    struct EquipmentShop has key {
        info: Info,
        base_sword_price: u64,
        base_armor_price: u64,
        base_shield_price: u64,
        base_potion_price: u64,
        balance: Balance<SUI>,
        game_id: ID
    }

  
    struct Dungeon has key {
        info: Info,
        rats: u64,
        goblins: u64,
        orcs: u64,
        berserker_orcs: u64,
        demons: u64,
        game_id: ID
    }


    // ###### HERO AND ENEMIES ######


    struct Hero has key {
        info: Info,
        level: u64,
        experience: u64,

        //Hero's name
        name: String,

        // Hero's Health Points if it reaches 0 
        //hero falls unconsious and loses the battle
        hp: u64,
        max_hp: u64,

        // The more strength a Hero has, 
        //the more damage he can inflict to enemies
        strength: u64,

        // The more constitution a Hero has, 
        //the more bonus hp he get when he level's up.
        constitution: u64,

        // The more grit a Hero has, the more he can withstand pain, 
        //which means he get's less damage from his enemies 
        grit: u64,

        armor: Option<Armor>,
        weapon: Option<Sword>,
        shield: Option<Shield>,
        inventory: Option<Potion>,
        game_id: ID
    }

    // Rat is the easiest enemy
    struct Rat has key{
        info: Info,
        hp: u64,
        strength: u64,
        constitution: u64,
        grit: u64,
        xp_on_death: u64,
        difficulty: u64,
        game_id: ID
    }

    // Not as easy as a rat but not a terrible threat either. Wields a plain Sword
    struct Goblin has key {
        info: Info,
        hp: u64,
        strength: u64,
        constitution: u64,
        grit: u64,
        xp_on_death: u64,
        weapon: Sword,
        difficulty: u64,
        game_id: ID
    }

    // Has Rare weapon and Shield
    struct Orc has key {
        info: Info,
        hp: u64,
        strength: u64,
        constitution: u64,
        grit: u64,
        xp_on_death: u64,
        weapon: Sword,
        shield: Shield,
        difficulty: u64,
        game_id: ID
    }

    // Has Epic weapons and armor
    struct BerserkerOrc has key {
        info: Info,
        hp: u64,
        strength: u64,
        constitution: u64,
        grit: u64,
        xp_on_death: u64,
        armor: Armor,
        left_hand: Sword,
        right_hand: Sword,
        difficulty: u64,
        game_id: ID
    }

    // Most Powerful minion. Has four hands and is equipped with mythic items
    // Rummors say that when a DM sends this minion after the Hero, the DM laughs hysterically
    struct Demon has key {
        info: Info,
        hp: u64,
        strength: u64,
        constitution: u64,
        grit: u64,
        xp_on_death: u64,
        armor: Armor,
        first_hand: Sword,
        second_hand: Sword,
        third_hand: Sword,
        fourth_hand: Sword,
        difficulty: u64,
        game_id: ID
    }


    // ###### ITEMS ######


    struct Sword has key, store {
        info: Info,
        damage: u64,
        rarity: u64,
        game_id: ID
    }

    struct Shield has key, store {
        info: Info,
        block_power: u64, //block_power lowers the incoming damage an enemy inflicts on hero
        rarity: u64,
        game_id: ID
    }

    struct Armor has key, store {
        info: Info,
        block_power: u64,
        rarity: u64,
        game_id: ID
    }

    struct Potion has key, store {
        info: Info,
        healing_power: u64, // Heals Hero's HP by healing power's amount
        rarity: u64,
        game_id: ID
    }


    // ###### CONSTANTS ######

    // Enemy Difficulty
    const EASY: u64 = 1;
    const MEDIUM: u64 = 2;
    const HARD: u64 = 3;
    const VERY_HARD: u64 = 4;
    const NIGHTMARE: u64 = 5;


    // Basic Stats
    const BASIC_HP: u64 = 100;
    const BASIC_STRENGTH: u64 = 15;
    const BASIC_CONSTITUTION: u64 = 15;
    const BASIC_GRIT: u64 = 15;
    const BASIC_XP_ON_DEATH: u64 = 250;


    // Rarity multiplies the effect of plain items and it's cost
    const PLAIN_RARITY: u64 = 1;
    const RARE_RARITY: u64 = 2;
    const EPIC_RARITY: u64 = 3;
    const LEGENDARY_RARITY: u64 = 4;
    const MYTHIC_RARITY: u64 = 5;


    // Error Codes
    const ENoSuchRarity: u64 = 500;
    const ENotEnoughMoney: u64 = 501;
    const EWrongGame: u64 = 502;
    const ENoSuchDifficulty: u64 = 503;
    const ENoRatsInTheDungeon: u64 = 504;
    const ENoGoblinsInTheDungeon: u64 = 505;
    const ENoOrcsInTheDungeon: u64 = 506;
    const ENoBerserkerOrcsInTheDungeon: u64 = 507;
    const ENoDemonsInTheDungeon: u64 = 508;
    const ENotStrongEnoughToFight: u64 = 509;
    const ENoTreasure: u64 = 510;
    const EBrokenItem: u64 = 511;


    const PLAYER_DEFEATED: u64 = 1000;


    // ###### NEW GAME FUNCTIONS ######

    // ####### Module init and create functions #######

    fun init(ctx: &mut TxContext){
        create_game(ctx)
    }

    public fun new_game(ctx: &mut TxContext){
        create_game(ctx)
    }

    fun create_game(ctx: &mut TxContext){
        let info = object::new(ctx);
        let game_id = *object::info_id(&info); // Copy id from info to game_id
        let sender = tx_context::sender(ctx); // Get admin's address

        // Create new game's Info
        transfer::freeze_object(GameInfo{
            info,
            admin: sender
        });

        //Create a DungeonMaster and transfer it to the owner
        transfer::transfer(
            DungeonMaster{
                info: object::new(ctx),
                game_id
            }, sender
        );

        // Create an EquipmentShop and share it so it is accessible by everyone
        transfer::share_object(
            EquipmentShop {
                info: object::new(ctx),
                base_sword_price: 15,
                base_armor_price: 18,
                base_shield_price: 10,
                base_potion_price: 6,
                balance: balance::zero(),
                game_id
            }
        );

        // Create the Dungeon and share it so it is accessible by everyone
        transfer::share_object(
            Dungeon {
                info: object::new(ctx),
                rats: 0,
                goblins: 0,
                orcs: 0,
                berserker_orcs: 0,
                demons: 0,
                game_id
            }
        )
    }

    public fun new_player(game: &GameInfo, name: vector<u8>, ctx: &mut TxContext): Hero {
        Hero {
            info: object::new(ctx),
            level: 1,
            name: utf8::string_unsafe(name),
            hp: BASIC_HP,
            max_hp: BASIC_HP,
            strength: BASIC_STRENGTH,
            constitution: BASIC_CONSTITUTION,
            grit: BASIC_GRIT,
            armor: option::some(create_armor(game, 1, ctx)),
            weapon: option::some(create_sword(game, 1, ctx)),
            shield: option::some(create_shield(game, 1, ctx)),
            inventory: option::some(create_potion(game, 1, ctx)),
            experience: 0,
            game_id: *object::info_id(&game.info) // Copy current game's id to new hero's game_id
        }
    }

    fun create_armor(game: &GameInfo, rarity: u64, ctx: &mut TxContext): Armor {
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);
        let base_block_power = 25;
        Armor {
            info: object::new(ctx),
            block_power: base_block_power * rarity,
            rarity,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_sword(game: &GameInfo, rarity: u64, ctx: &mut TxContext): Sword {
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);
        let base_dmg = 20;

        Sword {
            info: object::new(ctx),
            damage: base_dmg * rarity,
            rarity,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_shield(game: &GameInfo, rarity: u64, ctx: &mut TxContext): Shield {
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);
        let base_block_power = 35;
        Shield {
            info: object::new(ctx),
            block_power: base_block_power * rarity,
            rarity,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_potion(game: &GameInfo, rarity: u64, ctx: &mut TxContext): Potion {
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);
        let base_healing_power = 75;
        Potion {
            info: object::new(ctx),
            healing_power: base_healing_power * rarity,
            rarity,
            game_id: *object::info_id(&game.info)
        }
    }


    // ##### Enemy Creation ######
    fun create_rat(game: &GameInfo,  ctx: &mut TxContext): Rat {
        Rat {
            info: object::new(ctx),
            hp: BASIC_HP,
            strength: BASIC_STRENGTH,
            constitution: BASIC_CONSTITUTION,
            grit: BASIC_GRIT,
            xp_on_death: BASIC_XP_ON_DEATH,
            difficulty: EASY,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_goblin(game: &GameInfo, ctx: &mut TxContext): Goblin {
        Goblin {
            info: object::new(ctx),
            hp: BASIC_HP * MEDIUM,
            strength: BASIC_STRENGTH * MEDIUM,
            constitution: BASIC_CONSTITUTION * MEDIUM,
            grit: BASIC_GRIT * MEDIUM,
            xp_on_death: BASIC_XP_ON_DEATH * MEDIUM,
            weapon: create_sword(game, 1, ctx),
            difficulty: MEDIUM,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_orc(game: &GameInfo, ctx: &mut TxContext) : Orc {
            Orc {
            info: object::new(ctx),
            hp: BASIC_HP * HARD,
            strength: BASIC_STRENGTH * HARD,
            constitution: BASIC_CONSTITUTION * HARD,
            grit: BASIC_GRIT * HARD,
            xp_on_death: BASIC_XP_ON_DEATH * HARD,
            weapon: create_sword(game, 3, ctx),
            shield: create_shield(game, 3, ctx),
            difficulty: HARD,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_berserker_orc(game: &GameInfo, ctx: &mut TxContext): BerserkerOrc {
        BerserkerOrc {
            info: object::new(ctx),
            hp: BASIC_HP * VERY_HARD,
            strength: BASIC_STRENGTH * VERY_HARD,
            constitution: BASIC_CONSTITUTION * VERY_HARD,
            grit: BASIC_GRIT * VERY_HARD,
            xp_on_death: BASIC_XP_ON_DEATH * VERY_HARD,
            armor: create_armor(game, 4, ctx),
            left_hand: create_sword(game, 4, ctx),
            right_hand: create_sword(game, 4, ctx),
            difficulty: VERY_HARD,
            game_id: *object::info_id(&game.info)
        }
    }

    fun create_demon(game: &GameInfo, ctx: &mut TxContext): Demon {
        Demon {
            info: object::new(ctx),
            hp: BASIC_HP * NIGHTMARE,
            strength: BASIC_STRENGTH * NIGHTMARE,
            constitution: BASIC_CONSTITUTION * NIGHTMARE,
            grit: BASIC_GRIT * NIGHTMARE,
            xp_on_death: BASIC_XP_ON_DEATH * NIGHTMARE,
            armor: create_armor(game, 5, ctx),
            first_hand: create_sword(game, 5, ctx),
            second_hand: create_sword(game, 5, ctx),
            third_hand: create_sword(game, 5, ctx),
            fourth_hand: create_sword(game, 5, ctx),
            difficulty: NIGHTMARE,
            game_id: *object::info_id(&game.info)
        }
    }


    // ##### GAMEPLAY FUNCTIONS ######

        // ##### Buying Functions #####

    public fun buy_and_equip_sword(game: &GameInfo, shop: &mut EquipmentShop, hero: &mut Hero, rarity:u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        // validate rarity
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);

        // get the price for that rarity and check if the player's money equals or exceeds the price
        let sword_price = shop.base_sword_price * rarity;
        assert!(coin::value(payment) >= sword_price, ENotEnoughMoney);

        // Get the amount of money required for the sword and put it on shop's balance
        let money_for_sword = coin::balance_mut(payment);
        let paid = balance::split(money_for_sword, sword_price);
        balance::join(&mut shop.balance, paid);

        // Create a new sword, equip it and send old sword to player
        let new_sword = create_sword(game, rarity, ctx);
        let old_weapon = option::extract(&mut hero.weapon);
        
        option::fill(&mut hero.weapon, new_sword);

        transfer::transfer(old_weapon, tx_context::sender(ctx))
    }

    public fun buy_and_equip_armor(game: &GameInfo, shop: &mut EquipmentShop, hero: &mut Hero, rarity:u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);

        let armor_price = shop.base_armor_price * rarity;
        assert!(coin::value(payment) >= armor_price, ENotEnoughMoney);

        let money_for_armor = coin::balance_mut(payment);
        let paid = balance::split(money_for_armor, armor_price);

        balance::join(&mut shop.balance, paid);

        let new_armor = create_armor(game, rarity, ctx);
        let old_armor = option::extract(&mut hero.armor);
        option::fill(&mut hero.armor, new_armor);
        
        transfer::transfer(old_armor, tx_context::sender(ctx))
    }

    public fun buy_and_equip_shield(game: &GameInfo, shop: &mut EquipmentShop, hero: &mut Hero, rarity:u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);

        let shield_price = shop.base_shield_price * rarity;
        assert!(coin::value(payment) >= shield_price, ENotEnoughMoney);

        let money_for_shield = coin::balance_mut(payment);
        let paid = balance::split(money_for_shield, shield_price);
        balance::join(&mut shop.balance, paid);

        let new_shield = create_shield(game, rarity, ctx);
        let old_shield = option::extract(&mut hero.shield);
        option::fill(&mut hero.shield, new_shield);
        
        transfer::transfer(old_shield, tx_context::sender(ctx))
        
    }

    public fun buy_potion(game: &GameInfo, shop: &mut EquipmentShop, hero: &mut Hero, rarity:u64, payment: &mut Coin<SUI>, ctx: &mut TxContext){
        assert!((rarity > 0) && (rarity < 6), ENoSuchRarity);

        let potion_price = shop.base_potion_price * rarity;
        assert!(coin::value(payment) >= potion_price, ENotEnoughMoney);

        let money_for_potion = coin::balance_mut(payment);
        let paid = balance::split(money_for_potion, potion_price);

        let new_potion = create_potion(game, rarity, ctx);

        // If hero's inventory is empty put new potion in inventory
        // Else transfer it to sender
        if (!option::is_some(&hero.inventory)){
            option::fill(&mut hero.inventory, new_potion)
        } else {
            transfer::transfer(new_potion, tx_context::sender(ctx))
        };

        balance::join(&mut shop.balance, paid);
    }

    public fun use_potion(potion: Potion, player: &mut Hero){
        assert!(potion.game_id == player.game_id, EWrongGame);

        let Potion {
            info: potion_id,
            healing_power,
            rarity: _,
            game_id: _
        } = potion;

        let new_hp = player.hp + healing_power;

        player.hp = math::min(new_hp, *&player.max_hp);
        object::delete(potion_id)
    }

    public fun equip_sword(sword: Sword, player: &mut Hero, ctx: &mut TxContext) {
        assert!(sword.game_id == player.game_id, EWrongGame);

        // If player already has a sword equiped remove it and transfer it to his address
        if (option::is_some(&player.weapon)){
            let old_weapon = option::extract(&mut player.weapon);
            transfer::transfer(old_weapon, tx_context::sender(ctx));
        };

        option::fill(&mut player.weapon, sword)
    }

    public fun equip_armor(armor: Armor, player: &mut Hero, ctx: &mut TxContext) {
        assert!(armor.game_id == player.game_id, EWrongGame);

        if (option::is_some(&player.armor)){
            let old_armor = option::extract(&mut player.armor);
            transfer::transfer(old_armor, tx_context::sender(ctx));
        };

        option::fill(&mut player.armor, armor)
    }

    public fun equip_shield(shield: Shield, player: &mut Hero, ctx: &mut TxContext) {
        assert!(shield.game_id == player.game_id, EWrongGame);

        if (option::is_some(&player.shield)){
            let old_shield = option::extract(&mut player.shield);
            transfer::transfer(old_shield, tx_context::sender(ctx));
        };

        option::fill(&mut player.shield, shield)
    }


    

        // ###### Battle Functions #######

    // You must be a Dungeon Master to add enemy to Dungeon
    public fun add_enemy_to_dungeon(game: &GameInfo, admin: &DungeonMaster, dungeon: &mut Dungeon, enemy_difficulty: u64) {
        assert!(admin.game_id == *object::info_id(&game.info), EWrongGame);
        assert!(dungeon.game_id == *object::info_id(&game.info), EWrongGame);
        assert!((enemy_difficulty >= EASY) && (enemy_difficulty <= NIGHTMARE), ENoSuchDifficulty);

        // Add enemy to Dungeon
        if (enemy_difficulty == EASY) {
            dungeon.rats = dungeon.rats + 1;
        } else if (enemy_difficulty == MEDIUM) {
            dungeon.goblins = dungeon.goblins + 1;
        } else if (enemy_difficulty == HARD) {
            dungeon.orcs = dungeon.orcs + 1;
        } else if(enemy_difficulty == VERY_HARD) {
            dungeon.berserker_orcs = dungeon.berserker_orcs + 1;
        } else {
            dungeon.demons = dungeon.demons + 1;
        }
        
    }

    // Enter the dungeon and fight enemies
    public fun fight_in_the_dungeon(game: &GameInfo, dungeon: &mut Dungeon, enemy_difficulty: u64, player: &mut Hero, ctx: &mut TxContext) {
        //assert!(player.game_id == dungeon.game_id, EWrongGame);
        assert!(player.game_id == *object::info_id(&game.info), EWrongGame);
        assert!(dungeon.game_id == *object::info_id(&game.info), EWrongGame);
        assert!(player.hp > 0, ENotStrongEnoughToFight);
        assert!((enemy_difficulty >= EASY) && (enemy_difficulty <= NIGHTMARE), ENoSuchDifficulty);

        
        if (enemy_difficulty == EASY) {
            assert!(dungeon.rats != 0, ENoRatsInTheDungeon);
            let rat = create_rat(game, ctx);
            fight_rat(dungeon, rat, player)

        } else if (enemy_difficulty == MEDIUM) {
            assert!(dungeon.goblins != 0, ENoGoblinsInTheDungeon);
            let goblin = create_goblin(game, ctx);
            fight_goblin(dungeon, goblin, player)

        } else if (enemy_difficulty == HARD) {
            assert!(dungeon.orcs != 0, ENoOrcsInTheDungeon);
            let orc = create_orc(game, ctx);
            fight_orc(dungeon, orc, player)

        } else if(enemy_difficulty == VERY_HARD) {
            assert!(dungeon.berserker_orcs != 0, ENoBerserkerOrcsInTheDungeon);
            let berserker_orc = create_berserker_orc(game, ctx);
            fight_berserker_orc(dungeon, berserker_orc, player)

        } else {
            assert!(dungeon.demons != 0, ENoDemonsInTheDungeon);
            let demon = create_demon(game, ctx);
            fight_demon(dungeon, demon, player)
        }
    }

    // Fight a big Rat
    fun fight_rat(dungeon: &mut Dungeon, enemy: Rat, player: &mut Hero){
        
        let Rat {
            info: enemy_id ,
            hp: enemy_hp,
            strength: enemy_strength,
            constitution: _,
            grit: enemy_grit,
            xp_on_death: enemy_xp_on_death,
            difficulty: _,
            game_id: _
        } = enemy;

        let enemy_dmg = enemy_strength - get_protection_value(player);

        let player_dmg = get_attack_value(player) - enemy_grit;
        let player_hp = *&player.hp;

        while ((player_hp > 0) && (enemy_hp > 0)) {
            enemy_hp = enemy_hp - player_dmg;
            player_hp = player_hp - enemy_dmg;

            assert!(player_hp > 0, PLAYER_DEFEATED)
        };

        dungeon.rats = dungeon.rats - 1;
        player.hp = player_hp;

        player.experience = player.experience + enemy_xp_on_death;
        level_up_if_ready(player);

        object::delete(enemy_id);
    }

    // Fight a Goblin
    fun fight_goblin(dungeon: &mut Dungeon, enemy: Goblin, player: &mut Hero){
        let Goblin {
            info: enemy_id ,
            hp: enemy_hp,
            strength: enemy_strength,
            constitution: _,
            grit: enemy_grit,
            xp_on_death: enemy_xp_on_death,
            weapon,
            difficulty: _,
            game_id: _
        } = enemy;

        let enemy_dmg = enemy_strength + *&weapon.damage - get_protection_value(player);

        let player_dmg = get_attack_value(player) - enemy_grit;
        let player_hp = *&player.hp;

        while ((player_hp > 0) && (enemy_hp > 0)) {
            enemy_hp = enemy_hp - player_dmg;
            player_hp = player_hp - enemy_dmg;

            assert!(player_hp > 0, PLAYER_DEFEATED)
        };

        dungeon.goblins = dungeon.goblins - 1;

        player.hp = player_hp;

        player.experience = player.experience + enemy_xp_on_death;
        level_up_if_ready(player);

        destroy_sword(weapon);
        object::delete(enemy_id)
    }

    // Fight an Orc
    fun fight_orc(dungeon: &mut Dungeon,enemy: Orc, player: &mut Hero){
        let Orc {
            info: enemy_id,
            hp: enemy_hp,
            strength: enemy_strength,
            constitution: _,
            grit: enemy_grit,
            xp_on_death: enemy_xp_on_death,
            weapon,
            shield,
            difficulty: _,
            game_id: _
        } = enemy;

        let enemy_dmg = enemy_strength + *&weapon.damage - get_protection_value(player);

        let player_dmg = get_attack_value(player) - enemy_grit - *&shield.block_power;
        let player_hp = *&player.hp;

        while ((player_hp > 0) && (enemy_hp > 0)) {
            enemy_hp = enemy_hp - player_dmg;
            player_hp = player_hp - enemy_dmg;

            assert!(player_hp > 0, PLAYER_DEFEATED)
        };
        dungeon.orcs = dungeon.orcs - 1;
        player.hp = player_hp;

        player.experience = player.experience + enemy_xp_on_death;
        level_up_if_ready(player);

        
        destroy_sword(weapon);
        destroy_shield(shield);
        object::delete(enemy_id)
    }

    // Fight a Berserker Orc
    fun fight_berserker_orc(dungeon: &mut Dungeon, enemy: BerserkerOrc, player: &mut Hero){
        let BerserkerOrc {
            info: enemy_id,
            hp: enemy_hp,
            strength: enemy_strength,
            constitution: _,
            grit: enemy_grit,
            xp_on_death: enemy_xp_on_death,
            armor,
            left_hand,
            right_hand,
            difficulty: _,
            game_id: _
        } = enemy;

        let enemy_dmg = enemy_strength + *&right_hand.damage + *&left_hand.damage - get_protection_value(player);

        let player_dmg = get_attack_value(player) - enemy_grit - *&armor.block_power;
        let player_hp = *&player.hp;

        while ((player_hp > 0) && (enemy_hp > 0)) {
            enemy_hp = enemy_hp - player_dmg;
            player_hp = player_hp - enemy_dmg;

            assert!(player_hp > 0, PLAYER_DEFEATED)
        };
        dungeon.berserker_orcs = dungeon.berserker_orcs - 1;
        player.hp = player_hp;

        player.experience = player.experience + enemy_xp_on_death;
        level_up_if_ready(player);

        
        destroy_sword(left_hand);
        destroy_sword(right_hand);
        destroy_armor(armor);
        object::delete(enemy_id)
    }

        fun fight_demon(dungeon: &mut Dungeon, enemy: Demon, player: &mut Hero){
        let Demon {
            info: enemy_id,
            hp: enemy_hp,
            strength: enemy_strength,
            constitution: _,
            grit: enemy_grit,
            xp_on_death: enemy_xp_on_death,
            armor,
            first_hand,
            second_hand,
            third_hand,
            fourth_hand,
            difficulty: _,
            game_id: _
        } = enemy;

        let enemy_dmg = enemy_strength + *&first_hand.damage + *&second_hand.damage + *&third_hand.damage + *&fourth_hand.damage - get_protection_value(player);

        let player_dmg = get_attack_value(player) - enemy_grit - *&armor.block_power;
        let player_hp = *&player.hp;


        while ((player_hp > 0) && (enemy_hp > 0)) {

            enemy_hp = enemy_hp - player_dmg;


            player_hp = player_hp - enemy_dmg;

            assert!(player_hp > 0, PLAYER_DEFEATED)
        };

        dungeon.demons = dungeon.demons - 1;
        player.hp = player_hp;

        player.experience = player.experience + enemy_xp_on_death;
        level_up_if_ready(player);


        destroy_sword(first_hand);
        destroy_sword(second_hand);
        destroy_sword(third_hand);
        destroy_sword(fourth_hand);
        destroy_armor(armor);
        object::delete(enemy_id)
    }




    // ###### UTILITY FUNCTIONS ######

    fun get_attack_value(player: &mut Hero): u64{
        let weapon_dmg = option::borrow(&player.weapon).damage;
        let hero_strength = *&player.strength;

        let attack_value = weapon_dmg + hero_strength;
        attack_value
    }

    fun get_protection_value(player: &mut Hero): u64{
        let armor_block_value = option::borrow(&player.armor).block_power;
        let shield_block_value = option::borrow(&player.shield).block_power;
        let hero_grit = *&player.grit;

        let protection_value = armor_block_value + shield_block_value + hero_grit;
        protection_value
    }


    // Level up your hero if he has enough experience
    fun level_up_if_ready(player: &mut Hero){
        let xp_for_level = (player.level * 900) / 2;
        if (player.experience >= xp_for_level){
            while (player.experience >= xp_for_level){
                player.level = player.level + 1;
                player.strength = player.strength + 3;
                player.constitution = player.constitution + 3;
                player.grit = player.grit + 3;
                player.hp = player.hp + 30 + player.constitution;
                player.max_hp = player.max_hp + 30 + player.constitution;
                player.experience = player.experience - xp_for_level
            };
        }
    }


    fun destroy_sword(sword: Sword){
        let Sword{
            info: sword_id,
            damage: _,
            rarity: _,
            game_id: _
        } = sword;

        object::delete(sword_id)
    }

    fun destroy_armor(armor: Armor){
        let Armor {
            info: armor_id,
            block_power: _,
            rarity: _,
            game_id: _
        } = armor;

        object::delete(armor_id)
    }

    fun destroy_shield(shield: Shield){
        let Shield {
            info: shield_id,
            block_power: _,
            rarity: _,
            game_id: _
        } = shield;

        object::delete(shield_id)
    }

    // Only Dungeon Master can collect treasure
    public entry fun collect_treasure(dungeon_master: &DungeonMaster, shop: &mut EquipmentShop, ctx: &mut TxContext){
        assert!(dungeon_master.game_id == shop.game_id, EWrongGame);
        let treasure = balance::value(&shop.balance);
        assert!(treasure > 0, ENoTreasure);

        let gold = coin::take(&mut shop.balance, treasure, ctx);
        
        transfer::transfer(gold, tx_context::sender(ctx))
    }

}