*** Settings ***
Documentation     Deep inspection of HTTP traffic on asymmetric chain.
...               Nodes are located on different VMs.
Suite Setup       Start Connections
Suite Teardown    Close Connections
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot

*** Variables ***

*** Testcases ***
Start HTTP on h36_4 on Port 80
    [Documentation]    Starting HTTP service on docker container.
    Set Test Variables    client_name=h35_3    client_ip=10.0.35.3    server_name=h36_4    server_ip=10.0.36.4    service_port=80    ether_type=0x0800
    ...    proto=6    vxlan_gpe_port=2    vxlan_port=3
    Switch Connection    GPSFC6_CONNECTION
    Start HTTP Service on Docker    ${SERVER_NAME}    ${SERVICE_PORT}

Curl h36_2 from h35_3
    [Documentation]    Test HTTP request from a docker container to serving docker container.
    Switch Connection    GPSFC1_CONNECTION
    Curl from Docker    ${CLIENT_NAME}    ${SERVER_IP}    service_port=${SERVICE_PORT}

Start Endless Curl on h35_3 on port 80
    [Documentation]    Starting endless HTTP session for traffic inspection.
    Start Endless Curl from Docker    ${CLIENT_NAME}    ${SERVER_IP}    ${SERVICE_PORT}    sleep=1

On GBPSFC1 Send HTTP req h35_3-h36_4 to GBPSFC2
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=5    out_port=${VXLAN_GPE_PORT}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}    inner_dst_ip=${SERVER_IP}
    ...    next_hop_ip=${GBPSFC2}    nsi=255    proto=${PROTO}    dst_port=${SERVICE_PORT}
    ${nsp_35_3-nsp_36_4}    GET NSP Value From Flow    ${flow}
    Set Global Variable    ${NSP}    ${nsp_35_3-nsp_36_4}

On GBPSFC2 Send HTTP req h35_3-h36_4 to GBPSFC3
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC2_CONNECTION
    Inspect Service Function Forwarder    in_port=${VXLAN_GPE_PORT}    out_port=${VXLAN_GPE_PORT}    outer_src_ip=${GBPSFC1}    outer_dst_ip=${GBPSFC2}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}
    ...    inner_dst_ip=${SERVER_IP}    next_hop_ip=${GBPSFC3}    nsp=${NSP}    nsi=255    proto=${PROTO}

On GBPSFC3 Send HTTP req h35_3-h36_4 to GBPSFC2
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC3_CONNECTION
    Inspect Service Function    in_port=${VXLAN_GPE_PORT}    out_port=${VXLAN_GPE_PORT}    outer_src_ip=${GBPSFC2}    outer_dst_ip=${GBPSFC3}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}
    ...    inner_dst_ip=${SERVER_IP}    next_hop_ip=${GBPSFC2}    nsp=${NSP}    received_nsi=255

On GBPSFC2 Send HTTP req h35_3-h36_4 to GBPSFC4
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC2_CONNECTION
    Inspect Service Function Forwarder    in_port=${VXLAN_GPE_PORT}    out_port=${VXLAN_GPE_PORT}    outer_src_ip=${GBPSFC3}    outer_dst_ip=${GBPSFC2}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}
    ...    inner_dst_ip=${SERVER_IP}    next_hop_ip=${GBPSFC4}    nsp=${NSP}    nsi=254    proto=${PROTO}

On GBPSFC4 Send HTTP req h35_3-h36_4 to GBPSFC5
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC4_CONNECTION
    Inspect Service Function Forwarder    in_port=${VXLAN_GPE_PORT}    out_port=${VXLAN_GPE_PORT}    outer_src_ip=${GBPSFC2}    outer_dst_ip=${GBPSFC4}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}
    ...    inner_dst_ip=${SERVER_IP}    next_hop_ip=${GBPSFC5}    nsp=${NSP}    nsi=254    proto=${PROTO}

On GBPSFC5 Send HTTP req h35_3-h36_4 to GBPSFC4
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC5_CONNECTION
    Inspect Service Function    in_port=${VXLAN_GPE_PORT}    out_port=${VXLAN_GPE_PORT}    outer_src_ip=${GBPSFC4}    outer_dst_ip=${GBPSFC5}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}
    ...    inner_dst_ip=${SERVER_IP}    next_hop_ip=${GBPSFC4}    nsp=${NSP}    received_nsi=254

On GBPSFC4 Send HTTP req h35_3-h36_4 to GBPSFC6
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC4_CONNECTION
    Inspect Service Function Forwarder    in_port=${VXLAN_GPE_PORT}    out_port=${VXLAN_GPE_PORT}    outer_src_ip=${GBPSFC5}    outer_dst_ip=${GBPSFC4}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}
    ...    inner_dst_ip=${SERVER_IP}    next_hop_ip=${GBPSFC6}    nsp=${NSP}    nsi=253    proto=${PROTO}

On GBPSFC6 Send HTTP req h35_3-h36_4 to h36_4
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC6_CONNECTION
    Inspect Classifier Inbound    in_port=${VXLAN_GPE_PORT}    out_port=6    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}    inner_dst_ip=${SERVER_IP}    outer_src_ip=${GBPSFC4}
    ...    outer_dst_ip=${GBPSFC6}    nsp=${NSP}    nsi=253    proto=${PROTO}

On GBPSFC6 Send HTTP resp h36_4-h35_3 to GBPSFC1
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=6    out_port=${VXLAN_PORT}    eth_type=${ETHER_TYPE}    inner_src_ip=${SERVER_IP}    inner_dst_ip=${CLIENT_IP}
    ...    next_hop_ip=${GBPSFC1}    proto=${PROTO}    src_port=${SERVICE_PORT}

On GBPSFC1 Send HTTP resp h36_4-h35_3 to h35_3
    [Documentation]    HTTP traffic inspection.
    Switch Connection    GPSFC1_CONNECTION
    Inspect Classifier Inbound    in_port=${VXLAN_PORT}    out_port=5    eth_type=${ETHER_TYPE}    inner_src_ip=${SERVER_IP}    inner_dst_ip=${CLIENT_IP}    outer_src_ip=${GBPSFC6}
    ...    outer_dst_ip=${GBPSFC1}    proto=${PROTO}

Stop Endless Curl on h36_2 on port 80
    [Documentation]    Stopping endless HTTP session after traffic inspection finishes.
    Switch Connection    GPSFC1_CONNECTION
    Stop Endless Curl from Docker    ${CLIENT_NAME}

Stop HTTP on h36_2 on Port 80
    [Documentation]    Stopping HTTP service on the docker container.
    Switch Connection    GPSFC6_CONNECTION
    Stop HTTP Service on Docker    ${SERVER_NAME}
