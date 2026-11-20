"""Standard pytest entry points for the existing business and concurrency suites."""
import test_flow
import test_v14_contract
import test_concurrency
import runpy
from support import ROOT, Instance, find_bin


def test_operator_business_flow(mysql_instance):
    test_flow.verify(mysql_instance)


def test_v14_business_and_contract(mysql_instance, api_client):
    test_v14_contract.contract(api_client)
    test_v14_contract.verify(mysql_instance, api_client)


def test_real_mysql_concurrency_and_history(api_client):
    test_concurrency.verify(api_client.app.state.engine)


def test_sql_objects_and_rollback(tmp_path):
    module = runpy.run_path(str(ROOT / "database/modules/settlement/test_settlement_sql.py"))
    instance = Instance(find_bin(None), tmp_path)
    try:
        module["verify"](instance)
    finally:
        instance.close()
