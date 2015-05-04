#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst

"""
Run some "fake" login and wait until an IP address is banned by Fail2ban.

"""

__author__ = 'Quan Tong Anh'
__maintainer__ = 'Quan Tong Anh'
__email__ = 'quanta@robotinfra.com'

import logging
import time
import argparse
import subprocess
import shlex

log = logging.getLogger(__name__)


def __validate_arguments(name, timeout):
    # template for return dictonary
    return_dict = {'name': name, 'changes': {}, 'result': None, 'comment': ''}

    if type(timeout) is not int:
        return_dict['result'] = False
        return_dict['comment'] = 'Invalid timeout value: {}'.format(
            str(timeout))
        return False, return_dict

    # arguments valid
    return True, return_dict


def __is_timeouted(start_time, timeout):
    """
    Check if timed out, then return a function to format the return dict
    """

    # timeout exceeded
    if time.time() - start_time > timeout:
        return (True,
                lambda return_dict, name, source, jump: return_dict.update(
                    {'result': False,
                     'comment': ('Timeout exceeded (chain: "{}", '
                                 'rule: "-s {} -j {}")'.format(name, source, jump))}))
    return (False, None)


def wait_for_banned():
    """
    Wait for an iptables rule to appear in a specific chain,
    return False if exceeded a timeout value
    """

    argp = argparse.ArgumentParser(description=__doc__)
    argp.add_argument('-c', '--chain', metavar='CHAIN')
    argp.add_argument('-s', '--source', metavar='SOURCE')
    argp.add_argument('-j', '--jump', metavar='TARGET')
    argp.add_argument('-t', '--timeout', nargs='?', type=int, default=60, metavar='TIMEOUT')
    args = argp.parse_args()

    chain = args.chain
    source = args.source
    jump = args.jump
    timeout = args.timeout

    # validate arguments
    is_valid, ret = __validate_arguments(chain, timeout)
    if not is_valid:
        return ret

    # record timestamp before wait for process
    start_time = time.time()

    retcode = 1
    while retcode == 1:
        cmd = "/sbin/iptables -t filter -C {} -s {} -j {}".format(
            chain, source, jump)
        p = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, errors = p.communicate()
        retcode = p.returncode

        # check timeout
        is_timeouted, ret_fmt = __is_timeouted(start_time, timeout)
        if is_timeouted:
            ret_fmt(ret, chain, source, jump)
            return ret

        time.sleep(1)

    if retcode == 0:
        ret['result'] = True
        ret['comment'] = "chain: {}, rule: '-s {} -j {}'".format(
                chain, source, jump)
    else:
        ret['result'] = False
        ret['comment'] = return_data['stderr']
    return ret


if __name__ == '__main__':
    wait_for_banned()
