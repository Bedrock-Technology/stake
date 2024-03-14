from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deployer = accounts.load('mainnet-deployer')
    messageBus = "0xAd204986D6cB67A5Bc76a3CB8974823F43Cb9AAA"
    bridgeContract = "0xf763c9ec62a9ff998da4c205c0f78b7024c66b68" # OriginalTokenVault
    tokenContract = MockUniETH.deploy({'from':deployer}, publish_source=True)
    stakingContract = MockStaking.deploy(tokenContract, {'from':deployer}, publish_source=True)
    tokenContract.transferOwnership(stakingContract, {'from':deployer})
    wbnbContract = "0x2cB322C585D7640b9C41D9b4b58De4C3d60f2d6D"

    receiver = CelerMinterReceiver.deploy(
            messageBus,
            bridgeContract,
            wbnbContract,
            stakingContract,
            tokenContract,
            {'from': deployer},publish_source=True)