#[deny(warnings)]
module VaultType::Vault {
    // Uses >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    use aptos_framework::coin;
    use aptos_framework::coin::Coin;
    use std::signer;
    use aptos_framework::type_info::{Self};

    // Uses <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    // Structs >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    struct VaultStore<phantom CoinType> has key, store {
        value: Coin<CoinType>,
    }

    struct VaultStatus has key, copy {
        is_paused: bool
    }

    /// Container for coin type capabilities
    struct CoinCapabilities<phantom CoinType> has key {
        mint_capability: coin::MintCapability<CoinType>,
        burn_capability: coin::BurnCapability<CoinType>,
    }

    // Structs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    // Error codes >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    /// When caller is not admin
    const E_NOT_ADMIN: u64 = 0;

    /// When deposit while paused
    const E_DEPOSIT_PAUSED: u64 = 1;
    
    /// When withdraw while paused
    const E_WITHDRAW_PAUSED: u64 = 2;

    // Error codes <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Public entry functions >>>>>>>>>>>>>>>>>>>>>>>>>

    /// Pause deposit/withdraw
    public entry fun pause(account: &signer) 
    acquires VaultStatus
    {
        let type_info = type_info::type_of<VaultStatus>();
        let account_addr = signer::address_of(account);

        // Assert caller is Admin
        assert!(
            type_info::account_address(&type_info) == account_addr,
            E_NOT_ADMIN,
        );
        
        if(exists<VaultStatus>(account_addr)) {
            let vault_status = borrow_global_mut<VaultStatus>(account_addr);

            vault_status.is_paused = true;
        } else {
            move_to(account, VaultStatus{is_paused: true});
        };
    }

    /// Unpause deposit/withdraw
    public entry fun unpause(account: &signer) 
    acquires VaultStatus
    {
        let type_info = type_info::type_of<VaultStatus>();
        let account_addr = signer::address_of(account);
        // Assert caller is Admin
        assert!(
            type_info::account_address(&type_info) == account_addr,
            E_NOT_ADMIN,
        );

        if(exists<VaultStatus>(account_addr)) {
            let vault_status = borrow_global_mut<VaultStatus>(account_addr);
            vault_status.is_paused = false;
        } else {
            move_to(account, VaultStatus{is_paused: false});
        };
    }

    /// Deposit `amount` of `CoinType` from `account` to the vault
    public entry fun deposit<CoinType>(account: &signer, amount: u64)
    acquires VaultStore, VaultStatus
    {
        // Assert vault is not paused
        assert!(is_paused() == false, E_DEPOSIT_PAUSED);
        let coin = coin::withdraw<CoinType>(account, amount);
        // Get account address
        let account_addr = signer::address_of(account);
        if(!exists<VaultStore<CoinType>>(account_addr)) {
            move_to(account, VaultStore{value:coin});
        }
        else {
            let vault = borrow_global_mut<VaultStore<CoinType>>(account_addr);
            coin::merge(&mut vault.value, coin)
        }
    }

    /// Withdraw `amount` of `CoinType` from the vault to `account`
    public entry fun withdraw<CoinType>(account: &signer, amount: u64)
    acquires VaultStore, VaultStatus
    {
        // Assert vault is not paused
        assert!(is_paused() == false, E_WITHDRAW_PAUSED);

        // Get account address
        let account_addr = signer::address_of(account);

        if(exists<VaultStore<CoinType>>(account_addr)) {
            let vault = borrow_global_mut<VaultStore<CoinType>>(account_addr);
            let coin_to_withdraw = coin::extract(&mut vault.value, amount);
            coin::deposit(account_addr, coin_to_withdraw);
        }
    }
    // Public entry functions <<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Private functions >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    fun is_paused() : bool 
    acquires VaultStatus 
    {
        // Get contract address
        let type_info = type_info::type_of<VaultStatus>();

        // Get account address
        let addr = type_info::account_address(&type_info);

        if(exists<VaultStatus>(addr)) {
            return borrow_global<VaultStatus>(addr).is_paused
        };

        return false
    }
    // Private functions <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
}

// Tests >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

#[test_only]
module VaultType::VaultTest {
    // Uses >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    use std::string;
    use std::vector;
    use std::signer;
    use aptos_framework::coin;
    use VaultType::Vault;
    use std::unit_test;

    // Uses <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    // Structs >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    struct MoonCoin has key, store{
    }

    #[test_only]
    struct CoinCapabilities has key {
        mint_cap: coin::MintCapability<MoonCoin>,
        burn_cap: coin::BurnCapability<MoonCoin>,
    }
    // Structs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // Error codes >>>>>>>>>>>>>>>>>>>>>>>>>>

    /// When balance is not correct
    const E_WRONG_BALANCE: u64 = 3;

    // Error codes <<<<<<<<<<<<<<<<<<<<<<<<<<
    
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
        assert!(coin::balance<MoonCoin>(account_address) == 20, E_WRONG_BALANCE);
        Vault::deposit<MoonCoin>(account, 10);
        assert!(coin::balance<MoonCoin>(account_address) == 10, E_WRONG_BALANCE);
        Vault::withdraw<MoonCoin>(account, 10);
        assert!(coin::balance<MoonCoin>(account_address) == 20, E_WRONG_BALANCE);
    }
    
    #[test(account = @VaultType)]
    #[expected_failure(abort_code = 0)] // E_NOT_ADMIN
    /// deposit is expected to fail since vault is paused
    fun test_pause_with_non_admin(
        account: &signer
    ) {
        init_test_context(account);
        let alice = create_signer();
        Vault::pause(&alice);
    }

    #[test(account = @VaultType)]
    #[expected_failure(abort_code = 0)] // E_NOT_ADMIN
    /// deposit is expected to fail since vault is paused
    fun test_unpause_with_non_admin(
        account: &signer
    ) {
        init_test_context(account);
        let alice = create_signer();
        Vault::unpause(&alice);
    }

    #[test(account = @VaultType)]
    #[expected_failure(abort_code = 1)] // E_DEPOSIT_PAUSED
    /// deposit is expected to fail since vault is paused
    fun test_pause_with_deposit(
        account: &signer
    ) {
        init_test_context(account);
        Vault::pause(account);
        Vault::deposit<MoonCoin>(account, 10);
    }

    #[test(account = @VaultType)]
    #[expected_failure(abort_code = 2)] // E_WITHDRAW_PAUSED
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
        assert!(coin::balance<MoonCoin>(account_address) == 10, E_WRONG_BALANCE);
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
        assert!(coin::balance<MoonCoin>(account_address) == 30, E_WRONG_BALANCE);
    }

    #[test_only]
    fun create_signer(): signer {
        let signers = &mut unit_test::create_signers_for_testing(1);
        vector::pop_back(signers)
    }

    #[test_only]
    fun create_three_signer(): (signer, signer, signer) {
        let signers = &mut unit_test::create_signers_for_testing(3);
        (vector::pop_back(signers), vector::pop_back(signers), vector::pop_back(signers))
    }
}