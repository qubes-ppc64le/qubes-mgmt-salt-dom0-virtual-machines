# -*- coding: utf-8 -*-
# vim: set syntax=yaml ts=2 sw=2 sts=2 et :

##
# qvm.sys-usb
# ===========
#
# Installs 'sys-usb' UsbVM.
#
# Pillar data will also be merged if available within the ``qvm`` pillar key:
#   ``qvm:sys-usb``
#
# located in ``/srv/pillar/dom0/qvm/init.sls``
#
# Execute:
#   qubesctl state.sls qvm.sys-usb dom0
##

{% set default_template = salt['cmd.shell']('qubes-prefs default-template') %}

include:
  {% if salt['pillar.get']('qvm:sys-usb:disposable', false) %}
  - qvm.default-dispvm
  {% endif %}
  - qvm.hide-usb-from-dom0

{% from "qvm/template.jinja" import load -%}

# Avoid duplicated states
{% if salt['pillar.get']('qvm:sys-usb:name', 'sys-usb') != salt['pillar.get']('qvm:sys-net:name', 'sys-net') %}

{% load_yaml as defaults -%}
name:          sys-usb
present:
  {% if salt['pillar.get']('qvm:sys-usb:disposable', false) %}
  - class:     DispVM
  - template:  {{default_template}}-dvm
  {% endif %}
  - label:     red
  - mem:       300
  - flags:
    - net
prefs:
  - netvm:     ""
  - virt_mode: hvm
  - autostart: true
  - pcidevs:   {{ salt['grains.get']('pci_usb_devs', [])|yaml }}
  - pci_strictreset: false
service:
  - disable:
    - network-manager
    - meminfo-writer
{% if salt['pillar.get']('qvm:sys-usb:disposable', false) %}
require:
  - qvm:       {{default_template}}-dvm
{% endif %}
{%- endload %}

{{ load(defaults) }}

{% else %}

{% set vmname = salt['pillar.get']('qvm:sys-net:name', 'sys-net') %}

{{ vmname }}-usb:
  qvm.prefs:
    - name: {{ vmname }}
    - pcidevs: {{ (salt['grains.get']('pci_net_devs', []) + salt['grains.get']('pci_usb_devs', []))|yaml }}
    - pci_strictreset: False
    - require:
      - sls: qvm.sys-net

{% endif %}

qubes-input-proxy:
  pkg.installed: []

# Setup Qubes RPC policy
sys-usb-input-proxy:
  file.prepend:
    - name: /etc/qubes-rpc/policy/qubes.InputMouse
    - text: {{ salt['pillar.get']('qvm:sys-usb:name', 'sys-usb') }} dom0 allow,user=root
    - require:
      - pkg:       qubes-input-proxy
