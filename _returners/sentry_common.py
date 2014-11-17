#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2013, Bruno Clermont
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Salt returner that report error back to sentry

Configuration need something like:

sentry_common: http://deadbeef:beefdead@sentry.example.com/1

and http://pypi.python.org/pypi/raven installed
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Quan Tong Anh'
__email__ = 'quanta@robotinfra.com'

import logging

logger = logging.getLogger(__name__)

__virtualname__ = 'sentry_common'


def __virtual__():
    if not __virtualname__ in __opts__:
        logger.info("Missing '%s' value in configuration, skip.",
                    __virtualname__)
        return False
    if not __opts__[__virtualname__]:
        logger.info("Sentry returned turned off in configuration.")
        return False
    return __virtualname__


def returner(ret):
    """
    If an error occurs, log it to sentry
    """
    def send_sentry(message, result=None):

        pillar_data = __salt__['pillar.data']()

        # prepare grains
        grains = __salt__['grains.items']()
        # remove useless grains
        remove_grains = ('cpu_flags', 'gpus', 'id', 'kernel', 'path', 'ps',
                         'pythonpath', 'pythonversion', 'saltpath')
        for key in remove_grains:
            try:
                del grains[key]
            except KeyError:
                pass

        sentry_data = {
            'event_id': ret['jid'],
            'logger': "sentry_common.returner",
            'server_name': ret['id'],
            'platform': 'python',
            'culprit': result['name'],
        }
        del ret['jid']
        del ret['id']
        del result['name']

        sentry_data['extra'] = {
            'result': ret,
            'pillar': pillar_data,
            'grains': grains,
            'striped_grains': remove_grains
        }
        try:
            __salt__['raven.alert'](__opts__[__virtualname__], message, 'ERROR',
                                    sentry_data)
        except Exception, err:
            logger.error("Can't send message '%s' data '%s' to sentry: %s",
                         message, sentry_data, err)

    requisite_error = 'One or more requisite failed'
    try:
        logger.debug("Checking to see if there is a failed state")
        success = all(ret['return'][state]['result']
                      for state in ret['return'])
        logger.debug("success: {0}".format(success))
    except KeyError:
        send_sentry("Can't find 'return'")
    else:
        if not success:
            returned = ret['return']
            for state in returned:
                result = returned[state]['result']
                if result is not None and not result and \
                   returned[state]['comment'] != requisite_error:
                    send_sentry(returned[state]['comment'],
                                returned[state])
        else:
            logger.debug("All states run successfully")