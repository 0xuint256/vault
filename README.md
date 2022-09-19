![](.assets/cover-banner-blue.png)

[![Discord chat](https://img.shields.io/badge/docs-Econia-59f)](https://www.econia.dev)
[![Econia move documentation (move)](https://img.shields.io/badge/docs-Move-59f)](src/move/econia/build/Econia/docs)
[![Discord chat](https://img.shields.io/discord/988942344776736830?style=flat)](https://discord.gg/Z7gXcMgX8A)
[![License](https://img.shields.io/badge/license-Apache_2.0-white.svg)](LICENSE.md)


# Vault


*The Vault that web3 users can deposit/withdraw their digital asset on the Aptos blockchain*

- [Vault](#vault)
  - [Developer setup](#developer-setup)
    - [Command line setup](#command-line-setup)
  - [How Vault works](#how-vault-works)
    - [Deposit](#deposit)
    - [Withdraw](#withdraw)
    - [Pause](#pause)
    - [Unpause](#unpause)


If you haven't already, consider checking out Econia Labs' [Teach yourself Move on Aptos](https://github.com/econia-labs/teach-yourself-move) guide for some helpful background information!

## Developer setup

### Command line setup

1. First follow the [official Aptos developer setup guide](https://aptos.dev/guides/getting-started)

1. Then [install the `aptos` CLI](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli)

    ```zsh
    cargo install --git https://github.com/aptos-labs/aptos-core.git aptos --branch devnet
    aptos config set-global-config --config-type global
    aptos init
    ```
    * Note that this will go faster if [adding a precompiled binary](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli#install-precompiled-binary-easy-mode) to `~/.cargo/bin` rather than installing via `cargo`
    * If the precompiled binary has not been released yet, additionally consider [installing from Git](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli#install-from-git), a method that does not always require rebuilding intermediate artifacts


2. Then install the `move` CLI:

    ```zsh
    cargo install --git https://github.com/move-language/move move-cli
    ```

3. Clone the repo
    ```zsh
    git clone git@github.com:zen-ctrl/vault.git
    ```
4. Run the test
   ```zsh
    aptos move test
    ```


## How Vault works
### Deposit
    Users can deposit any type of their token to the vault.
### Withdraw
    Users can withdraw any type of their token that they deposited to the vault.
### Pause
    Admin can disable the deposit of the vault
### Unpause
    Admin can enable the deposit of the vault
