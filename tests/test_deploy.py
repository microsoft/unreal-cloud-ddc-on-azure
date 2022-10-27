#  ---------------------------------------------------------
#  Azure Game Developer Virtual Machine 
# 
# Copyright (c) Microsoft Corporation. All rights reserved.
#  ---------------------------------------------------------
"""
Post Deployment Tests

Environment Variables

RG: Resource Group of Application
AAD_ID: Azure SP Application ID used for Authentication
OBJ_ID: Azure SP Object ID used for Authentication
AAD_SECRET: Azure Tenant
SUBSCRIPTION_ID: Azure Subscription ID

Install the latest testing utilities before using this file.

`pip install ../../../src/microsoft-industrailai`

After setting variables, and installing testing utiltiies, execute using the followwing command.

`pytest test_vm_installations.py`

"""
from microsoft.industrialai.utils.test_utils import get_vm_name 

def test_get_compute():
    assert get_vm_name()
