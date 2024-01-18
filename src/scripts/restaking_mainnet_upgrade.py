from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin

    eigenpod_manager = '0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338'
    gnosis_safe = accounts.at('0xAeE017052DF6Ac002647229D58B786E380B9721A', {'force':True})
    proxy_admin_contract = ProxyAdmin.at('0xa5F2B6AB5B38b88Ba221741b3A189999b4c889C6')
    staking_proxy = '0x4beFa2aA9c305238AA3E0b5D17eB20C045269E9d'
    owner = accounts.load('mainnet-owner')
    deployer = accounts.load('mainnet-deployer')

    accounts[9].transfer(gnosis_safe, '10 ethers')
    accounts[9].transfer(owner, '10 ethers')
    accounts[9].transfer(deployer, '10 ethers')

    # simulate staking upgrade
    staking_contract = RockXStaking.deploy( {'from': deployer})
    proxy_admin_contract.upgrade(staking_proxy, staking_contract, {'from': gnosis_safe})

    # simulate restaking deployment
    restaking_contract = RockXRestaking.deploy( {'from': owner})
    restaking_proxy = TransparentUpgradeableProxy.deploy(
            restaking_contract.address, deployer, b'',
            {'from': deployer})

    #init 
    transparent_restaking = Contract.from_abi("RockXRestaking",restaking_proxy, RockXRestaking.abi)
    transparent_restaking.initialize(eigenpod_manager, {'from': owner})
    
    # set eigenpod to staking contract
    transparent_staking = Contract.from_abi("RockXStaking",staking_proxy, RockXStaking.abi)
    transparent_staking.setRestakingAddress(transparent_restaking.eigenPod(), {'from':gnosis_safe})
    print("restaking address", transparent_staking.addrRestaking(),transparent_staking.restakingWithdrawalCredentials()) 

    # simulate
