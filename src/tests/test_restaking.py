import pytest
import time
import sys
import brownie
import random

from pathlib import Path
from brownie import convert
from brownie import *
from conftest import deps

""" test of restaking a validator """
def test_restaking(setup_contracts, owner, deployer, pubkeys, sigs):
    transparent_xeth, transparent_staking, transparent_redeem = setup_contracts

    transparent_staking.registerRestakingValidators(pubkeys, sigs, {'from': owner})

    assert transparent_staking.getRegisteredValidatorsCount() == len(pubkeys)
    results = transparent_staking.getRegisteredValidators(0, len(pubkeys))

    # setup restaking deployment
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    restaking_contract = RockXRestaking.deploy( {'from': owner})
    restaking_proxy = TransparentUpgradeableProxy.deploy(
            restaking_contract.address, deployer, b'',
            {'from': deployer})

    #init 
    eigenpod_manager = '0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338'
    transparent_restaking = Contract.from_abi("RockXRestaking",restaking_proxy, RockXRestaking.abi)
    transparent_restaking.initialize('0x91E677b07F7AF907ec9a428aafA9fc14a0d3A338', {'from': owner})

    # set eigenpod to staking contract
    transparent_staking.setRestakingAddress(transparent_restaking.eigenPod(), {'from':owner})
    print("restaking address", transparent_staking.addrRestaking(),transparent_staking.restakingWithdrawalCredentials()) 

    # mint
    transparent_staking.toggleWhiteList(owner, {'from':owner})
    assert transparent_staking.isWhiteListed(owner) == True
    transparent_staking.mint(0, time.time() + 600, {'from':owner, 'value': '64 ether'})

    # stake
    transparent_staking.stake({'from':owner})
