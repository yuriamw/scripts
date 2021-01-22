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
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = 'Download builds from Jenkins to manipulate files on rootfs.')
    parser.add_argument('-j', '--job',       action="store", type=int,  help='Jenkins job number')
    parser.add_argument('-t', '--type',      action="store",            help='Jenkins job type'
                                                                            , default='main'
                                                                            , choices=['main', 'eng', 'cont'])
    parser.add_argument(      '--user',       action="store",           help='Username')
    parser.add_argument(      '--passwd',     action="store",           help='Password')
    #parser.add_argument(      '--split',   action="store_true",         help='Split files by one level')
    #parser.add_argument('-e', '--exclude', action="append",             help='Exclude file (w/o path) from search. Could be used multiple times')
    #parser.add_argument(      'infiles',                     nargs="+", help='Files/directories to process')

    args = parser.parse_args()
    #job = int(args.job)
    job = args.job

    #print(args)

    #urllib.parse.quote("znextgen/valhalla", safe='')
    #url = "{}/{}/{}/{}".format(jenkins_server[args.type]['loc'], jenkins_server[args.type]['name'], job, 'api/json')
    url = "{}/{}/{}/{}".format(jenkins_server[args.type].http, jenkins_server[args.type].name, job, 'api/json')
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

        if build_platform != "charter-humaxwb20-powerup":
            continue

        if build_type != "tst":
            continue

        url = "{}/{}/{}/{}-{}".format(jenkins_server[args.type].ftp, jenkins_server[args.type].name, job, build_platform, build_type)
        ftpurl = urllib.parse.urlsplit(url)
        ftp = FTP(host=ftpurl.netloc)
        ftp.login(user=args.user, passwd=args.passwd)
        ftp.cwd(ftpurl.path)

        ftp_list = []
        ftp.retrlines('NLST', ftp_list.append)
        rootfs_zip_indices = [ i for i, s in enumerate(ftp_list) if 'rootfs.zip' in s ]
        print("Found {} rootfs file(s):".format(len(rootfs_zip_indices)))
        for n in rootfs_zip_indices:
            print("  {}".format(ftp_list[n]))
        assert len(rootfs_zip_indices) == 1, "I can handle excatly one rootfs.zip file"

        rootfs_idx = rootfs_zip_indices[0]
        rootfs_zip = ftp_list[rootfs_idx]

        subdir = os.path.join("{}-{}".format(jenkins_server[args.type].name, job), "{}-{}".format(build_platform, build_type))
        localfile = os.path.join(subdir, rootfs_zip)

        if os.path.exists(subdir):
            print("Remove target directory ...")
            shutil.rmtree(subdir)

        print("Downloading {} to {} ...".format(rootfs_zip, subdir))
        os.makedirs(subdir)
        ftp.retrbinary('RETR ' + rootfs_zip, open(localfile, 'wb').write)
        ftp.close()

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
            zip.extractall(members=supervisor_yaml_members, path=subdir)

        if os.path.exists(localfile):
            print("Remove rootfs.zip ...")
            os.remove(localfile)
