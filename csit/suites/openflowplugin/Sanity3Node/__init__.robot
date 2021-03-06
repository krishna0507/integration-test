*** Settings ***
Documentation     Test suite for the OpenDaylight base edition with of13, aimed for statistics manager
Suite Setup       Start Suite
Suite Teardown    Utils.Stop Mininet
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${start}          sudo python DynamicMininet.py

*** Keywords ***
Start Suite
    Log    Start the test on the base edition
    ${mininet_conn_id}=    Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Set Suite Variable    ${mininet_conn_id}
    Login With Public Key    ${TOOLS_SYSTEM_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Put File    ${CURDIR}/../../../libraries/DynamicMininet.py    .
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start}
    Read Until    mininet>
    Write    start_with_cluster ${ODL_SYSTEM_IP},${ODL_SYSTEM_2_IP},${ODL_SYSTEM_3_IP}
    Read Until    mininet>
