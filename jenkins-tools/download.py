#! /usr/bin/env python3

import argparse
import os
import shutil
import urllib.parse
import requests
from ftplib import FTP
import json
import zipfile
#import re
import hashlib

from collections import namedtuple

#######################################################################
#lastSuccessfulBuild
#api/json
#ReleaseNotes_znextgen_valhalla_continuous_charter-humaxwb20-powerup-tst_31729.html

JenkinsServer = namedtuple('JenkinsServer', [ 'name', 'http', 'ftp' ])

jenkins_server = {
    'main': JenkinsServer(
        'VALHALLA',
        'https://jenkins.developonbox.ru/view/Valhalla/job',
        'ftp://ftp.developonbox.ru/common/SCM/builds/Valhalla'
    ),
    'eng':  JenkinsServer(
        'VALHALLA_ENG',
        'https://jenkins.developonbox.ru/view/Valhalla/job',
        'ftp://ftp.developonbox.ru/common/SCM/builds/Valhalla'
    ),
    'cont': JenkinsServer(
        'znextgen_valhalla_continuous',
        'https://jenkins.zodiac.tv/job',
        'ftp://ftp.developonbox.ru/common/SCM/builds/Valhalla'
    ),
}

rootfs_zip_name_part = ".rootfs.zip"
nfs_zip_name_part = "nfs_image"

build_exclude_suffixes = [
    "-oemstubs",
    "-vbs",
    "-oem_tests",
    "-unit_tests",
]

build_excludes = [
    "charter-moto2500-powerup",
    "charter-motoastb-powerup",
    "charter-pace-powerup",
    "zodiac-motoastb-sfw",
    "zodiac-moto2500-sfw",
    "zodiac-pace-sfw",
    "zodiac-mingw-powerup",
    "zodiac-arm_android-sfw",
    "zodiac-arm_android-chiclet",
    "zodiac-arm_android-fwupd",
    "zodiac-mediaroom-zebra",
    "zodiac-pc_linux-metrological",
]

#######################################################################
def get_run_params(run_url):
    params = urllib.parse.urlsplit(run_url)

    paramlist = params.path.split(',')
    #('/job/znextgen_valhalla_continuous/build_platform=zodiac-humaxwb20-powerup', 'build_type=tst')
    build_platform = ""
    build_type     = ""
    for p in paramlist:
        pname = "build_platform"
        pnum  = p.find(pname)
        if pnum >= 0:
            build_platform = p[pnum + len(pname) + 1 : ]
        pname = "build_type"
        pnum  = p.find(pname)
        if pnum >= 0:
            btstr = p[pnum + len(pname) + 1 : ]
            build_type = btstr[ : btstr.find('/')]

    return build_platform, build_type

#######################################################################
def artifact_name(art_type):
    if art_type == "rootfs":
        ret = rootfs_zip_name_part
    elif art_type == "nfs":
        ret = nfs_zip_name_part

    assert ret != None, "Unknown artifact type"

    return ret

#######################################################################
def artifact_subdir(art_type, rootfs_zip, job):
    if art_type == "rootfs":
        ret = rootfs_zip[:len(rootfs_zip) - len(rootfs_zip_name_part)]
    elif art_type == "nfs":
        ret = rootfs_zip[:len(rootfs_zip) - len("-{}.zip".format(job))]

    assert ret != None, "Unknown artifact type"

    return ret

#######################################################################
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = 'Download builds from Jenkins to manipulate files on rootfs.')
    parser.add_argument('-j', '--job',           action="store",    help='Jenkins job number'
                                                                        , type=int
                                                                        , required=True)
    parser.add_argument('-t', '--type',          action="store",    help='Jenkins job type'
                                                                        , default='main'
                                                                        , choices=['main', 'eng', 'cont'])
    parser.add_argument('-c', '--build-config',  action="append",   help='Use selected build config(s) only')
    parser.add_argument('-v', '--build-variant', action="append",   help='Use selected build-variant(s) only'
                                                                        , choices=['dev', 'tst', 'prd'])
    parser.add_argument('-a', '--artifact',      action="store",    help='Jenkins artifact'
                                                                        , default='rootfs'
                                                                        , choices=['rootfs', 'nfs'])
    parser.add_argument(      '--user',          action="store",    help='Username')
    parser.add_argument(      '--passwd',        action="store",    help='Password')
    parser.add_argument('-o', '--output',        action="store",    help='Save downloaded files to OUTPUT'
                                                                        , default='.')
    #parser.add_argument('-e', '--exclude', action="append",             help='Exclude file (w/o path) from search. Could be used multiple times')
    #parser.add_argument(      'infiles',                     nargs="+", help='Files/directories to process')

    args = parser.parse_args()
    #job = int(args.job)
    job = args.job

    output = args.output

    #print(args)

    #urllib.parse.quote("znextgen/valhalla", safe='')
    url = "{}/{}/{}/api/json".format(jenkins_server[args.type].http, jenkins_server[args.type].name, job)
    #print(url)
    print("Request build info ...")
    response = requests.get(url, auth=(args.user, args.passwd))
    #print(response.text)
    build_info = json.loads(response.text)
    #print(json.dumps(build_info, indent=4))

    for run in build_info['runs']:
        if run['number'] != job:
            continue
        build_platform, build_type = get_run_params(run['url'])
        #ReleaseNotes_znextgen_valhalla_continuous_charter-humaxwb20-powerup-tst_31729.html
        #rn_url = "{}/artifact/output/ReleaseNotes_{}_{}-{}_{}.html".format(run['url'], jenkins_server[args.type].name, build_platform, build_type, job)
        #rn = response = requests.get(rn_url, auth=(args.user, args.passwd))

        if args.build_config:
            if build_platform not in args.build_config:
                continue

        if args.build_variant:
            if build_type not in args.build_variant:
                continue

        need_exclude = False
        for suff in build_exclude_suffixes:
            if build_platform.endswith(suff):
                need_exclude = True
                break
        for cnf in build_excludes:
            if cnf == build_platform:
                need_exclude = True
                break

        if need_exclude:
            print("Skip {} as it has no {}".format(build_platform, rootfs_zip_name_part))
            continue

        url = "{}/{}/{}/{}-{}".format(jenkins_server[args.type].ftp, jenkins_server[args.type].name, job, build_platform, build_type)
        ftpurl = urllib.parse.urlsplit(url)
        ftp = FTP(host=ftpurl.netloc)
        ftp.login(user=args.user, passwd=args.passwd)
        ftp.cwd(ftpurl.path)

        ftp_list = []
        ftp.retrlines('NLST', ftp_list.append)
        rootfs_zip_indices = [ i for i, s in enumerate(ftp_list) if artifact_name(args.artifact) in s ]
        print("Found {} rootfs file(s):".format(len(rootfs_zip_indices)))
        for n in rootfs_zip_indices:
            print("  {}".format(ftp_list[n]))

        for rootfs_idx in rootfs_zip_indices:

            rootfs_zip = ftp_list[rootfs_idx]

            subdir = os.path.join(output, "{}-{}".format(jenkins_server[args.type].name, job), "{}-{}".format(build_platform, build_type))
            rootfs_subdir = artifact_subdir(args.artifact, rootfs_zip, job)
            extract_dir = os.path.join(subdir, rootfs_subdir)
            localfile = os.path.join(subdir, rootfs_zip)
            #print(subdir)
            #print(localfile)
            #print(extract_dir)
            #continue

            if os.path.exists(localfile):
                print("Remove old target zip ...")
                os.remove(localfile)
            if os.path.exists(extract_dir):
                print("Remove old target directory ...")
                shutil.rmtree(extract_dir)

            print("Downloading {} to {} ...".format(rootfs_zip, subdir))
            os.makedirs(subdir, exist_ok=True)
            os.makedirs(extract_dir, exist_ok=True)
            ftp.retrbinary('RETR ' + rootfs_zip, open(localfile, 'wb').write)

            # NOTE: The order is important!
            supervisor_yaml = [
                "etc/zodiac/configs/supervisor.yaml",
                "home/zodiac/supervisor.yaml"
            ]
            print("Extracting supervisor.yaml ...")
            with zipfile.ZipFile(localfile) as zip:
                for sy_name in supervisor_yaml:
                    supervisor_yaml_members = [ s for s in zip.namelist() if sy_name in s ]
                    if len(supervisor_yaml_members) > 0:
                        print("  found: {}".format(sy_name))
                        break
                zip.extractall(members=supervisor_yaml_members, path=extract_dir)

            if os.path.exists(localfile):
                print("Remove {} ...".format(rootfs_zip_name_part))
                os.remove(localfile)

        ftp.close()
