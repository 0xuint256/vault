#[deny(warnings)]
module VaultType::Vault {
    use aptos_framework::coin;
    use aptos_framework::coin::Coin;
    
    use std::signer;

    use aptos_framework::type_info::{Self};

    struct VaultStore<phantom CoinType> has key, store {
        value: Coin<CoinType>,
    }

    struct VaultStatus has key, copy {
        is_paused: bool
    }

    struct CoinCapabilities<phantom CoinType> has key {
        mint_capability: coin::MintCapability<CoinType>,
        burn_capability: coin::BurnCapability<CoinType>,
    }

    public entry fun pause(account: &signer) 
    acquires VaultStatus
    {
        let type_info = type_info::type_of<VaultStatus>();
        let account_addr = signer::address_of(account);

        assert!(
            type_info::account_address(&type_info) == account_addr,
            0,
        );
        
        if(exists<VaultStatus>(account_addr)) {
            let vault_status = borrow_global_mut<VaultStatus>(account_addr);

            vault_status.is_paused = true;
        } else {
            move_to(account, VaultStatus{is_paused: true});
        };
    }

    public entry fun unpause(account: &signer) 
    acquires VaultStatus
    {
        let type_info = type_info::type_of<VaultStatus>();
        let account_addr = signer::address_of(account);
        assert!(
            type_info::account_address(&type_info) == account_addr,
            0,
        );

        if(exists<VaultStatus>(account_addr)) {
            let vault_status = borrow_global_mut<VaultStatus>(account_addr);
            vault_status.is_paused = false;
        } else {
            move_to(account, VaultStatus{is_paused: false});
        };
    }

    public fun is_paused() : bool 
    acquires VaultStatus 
    {
        let type_info = type_info::type_of<VaultStatus>();
        let addr = type_info::account_address(&type_info);

        if(exists<VaultStatus>(addr)) {
            return borrow_global<VaultStatus>(addr).is_paused
        };

        return false
    }

    public entry fun deposit<CoinType>(account: &signer, amount: u64)
    acquires VaultStore, VaultStatus
    {
        assert!(is_paused() == false, 1);
        let coin = coin::withdraw<CoinType>(account, amount);
        let account_addr = signer::address_of(account);
        if(!exists<VaultStore<CoinType>>(account_addr)) {
            move_to(account, VaultStore{value:coin});
        }
        else {
            let vault = borrow_global_mut<VaultStore<CoinType>>(account_addr);
            coin::merge(&mut vault.value, coin)
        }
    }


    public entry fun withdraw<CoinType>(account: &signer, amount: u64)
    acquires VaultStore, VaultStatus
    {
        assert!(is_paused() == false, 2);

        let account_addr = signer::address_of(account);

        if(exists<VaultStore<CoinType>>(account_addr)) {
            let vault = borrow_global_mut<VaultStore<CoinType>>(account_addr);
            let coin_to_withdraw = coin::extract(&mut vault.value, amount);
            coin::deposit(account_addr, coin_to_withdraw);
        }
    }

}


#[test_only]
module VaultType::VaultTest {
    use std::string;
    use std::signer;
    use aptos_framework::coin;
    use VaultType::Vault;
    struct MoonCoin has key, store{

    }

    #[test_only]
    struct CoinCapabilities has key {
        mint_cap: coin::MintCapability<MoonCoin>,
        burn_cap: coin::BurnCapability<MoonCoin>,
    }
    #[test_only] 
    /// initialize token, register account, mint 30 coin, deposit 10 to vault
    fun init_test_context(account: &signer) {
        let name: string::String = string::utf8(b"MoonCoin");
        let symbol: string::String = string::utf8(b"MC");
        let decimals: u64 = 4;

        let (mint_cap, burn_cap) = coin::initialize<MoonCoin>(
            account,
            name,
            symbol,
            decimals,
            true
        );
        
        let coin1 = coin::mint<MoonCoin>(30, &mint_cap);

        let account_address = signer::address_of(account);
        coin::register<MoonCoin>(account);

        coin::deposit<MoonCoin>(account_address, coin1);

        move_to(account, CoinCapabilities {
            mint_cap,
            burn_cap
        });

        Vault::deposit<MoonCoin>(account, 10);

    }

     #[test(account=@VaultType)]
    fun test_mint(
        account: &signer
    ) {
        let account_address = signer::address_of(account);

        init_test_context(account);

        assert!(coin::balance<MoonCoin>(account_address) == 20, 0);

        Vault::deposit<MoonCoin>(account, 10);

        assert!(coin::balance<MoonCoin>(account_address) == 10, 0);

        Vault::withdraw<MoonCoin>(account, 10);
        
        assert!(coin::balance<MoonCoin>(account_address) == 20, 0);
    }
 
    #[test(account = @VaultType)]
    #[expected_failure(abort_code = 1)]
    /// deposit is expected to fail since vault is paused
    fun test_pause_with_deposit(
        account: &signer
    ) {
        init_test_context(account);
        Vault::pause(account);
        Vault::deposit<MoonCoin>(account, 10);
    }

    #[test(account = @VaultType)]
    #[expected_failure(abort_code = 2)]
    /// withdraw is expected to fail since vault is paused
    fun test_pause_with_withdraw(
        account: &signer
    ) {
        init_test_context(account);
        Vault::pause(account);
        Vault::withdraw<MoonCoin>(account, 10);
    }


    #[test(account = @VaultType)]
    /// test deposit after vault is unpaused
    fun test_unpause_with_deposit(
        account: &signer
    ) {
        init_test_context(account);
        Vault::unpause(account);
        Vault::deposit<MoonCoin>(account, 10);
        let account_address = signer::address_of(account);
        assert!(coin::balance<MoonCoin>(account_address) == 10, 3);
    }

    #[test(account = @VaultType)]
    /// test withdraw after vault is unpaused
    fun test_unpause_with_withdraw(
        account: &signer
    ) {
        init_test_context(account);
        Vault::unpause(account);
        Vault::withdraw<MoonCoin>(account, 10);
        let account_address = signer::address_of(account);

        assert!(coin::balance<MoonCoin>(account_address) == 30, 0);
    }

}