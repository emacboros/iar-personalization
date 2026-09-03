#!/bin/bash
# RETIRED (continuo cycle 12, 2026-09-03) -- do not use, do not copy.
#
# This was the standalone agora voice-channel probe (v1, cycle 77).
# Its logic now lives ONLY in fleet-check.sh check 0c (v2.12+).
# Why retired: the inline copy in fleet-check was justified (the
# standalone cannot be sourced from fleet-check: `ssh bash -s <`
# makes $0=bash, script-relative paths resolve wrong on sophon),
# but the standalone kept existing as a twin -- and a twin with
# zero executions on record is a drift waiting to happen, the same
# class as the THREADS banks and the DIGEST twins.
#
# NOT HERE. Write probe changes to fleet-check.sh check 0c.
# History: git log --follow knowledge/aria/bin/agora-probe.sh
exit 3
