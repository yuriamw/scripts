#! /usr/bin/env python3
#############################################################################
# Get git-log from gerrit and generates table with commits
#
# See below for outformat_ods and set True/False accordingly
#
# Output formats: ODS, ODT, HTML, CSV
#   ODS       is the best usable
#   ODT(list) is the very close to ODS
#   HTML      is OK for quick checks
#   CSV       is poor for imports
#
# Requires:
#   ODFPy installed
#      pip3 install odfpy
#
# Needs user login:password on commandline
#
# TODO:
#  - Ask for password
#  - DOCX/XLSX
#  - JSON? XML?
#  - Upload to corporate Sharepoint
#  - Embedd forms/controls into generated document to provide recors management for integrators
#  - Work on local git repository. Is it usefull?
#  - What else?
#############################################################################
import os
import sys
import argparse
import requests
import json
import re
import urllib.parse
# Import ODFPy
#   Documentation is poor but it works and easy to install
# https://stackoverflow.com/questions/949171/odfpy-documentation
# https://raw.githubusercontent.com/Guts/Metadator/master/test/test_odf_genexample.py
# https://gist.github.com/balasankarc/1832670ec8ddd9a34d33
from odf.opendocument import OpenDocumentSpreadsheet, OpenDocumentText
from odf.text import P, A, List, ListItem, ListStyle, ListLevelStyleNumber
from odf.table import Table, TableRow, TableColumn, TableCell
from odf.style import Style, TextProperties, ParagraphProperties, TableColumnProperties, TableCellProperties, ListLevelProperties
from odf import teletype

gerrit_auth = []

print("Python {0}.{1}.{2}".format(sys.version_info.major, sys.version_info.minor, sys.version_info.micro))
if sys.version_info.major < 3:
    sys.exit("ERROR: need Python version 3")

# May be useful for debugging
exit_on_error = True

gerrit     = "https://gerrit.developonbox.ru"
project    = urllib.parse.quote("znextgen/valhalla")
jira       = "https://jira.zodiac.tv"

outfile_base  = "out"

outformat_ods  = False
outformat_odt  = False
outformat_html = False
outformat_csv  = False

odt_table      = False

outfile_csv   = outfile_base + ".csv"
outfile_html  = outfile_base + ".html"
outfile_odt   = outfile_base + ".odt"
outfile_ods   = outfile_base + ".ods"

dst_commit = ""
src_commit = ""

parser = argparse.ArgumentParser(description="Script requests gerrit for commit log between two points in history and build ODT/ODS/HTML documetns for further analyzis")
parser.add_argument("-g", "--gerrit",                     action="store",      help="Gerrit URL. Default: {}".format(gerrit) )
parser.add_argument("-p", "--project",                    action="store",      help="Gerrit project name. Default: {}".format(project) )
parser.add_argument("-j", "--jira",                       action="store",      help="Jira URL. Default: {}".format(jira) )
parser.add_argument("-o", "--out",                        action="store",      help="The base name w/o ext for output file. Ext added automatically. Default: {}".format(outfile_base) )
parser.add_argument(      "--ods",                        action="store_true", help="Generate OpenDocument Spreadsheet (ODS). Default: {}".format(outformat_ods) )
parser.add_argument(      "--odt",                        action="store_true", help="Generate OpenDocument Text (ODT). Default: {}".format(outformat_odt) )
parser.add_argument(      "--html",                       action="store_true", help="Generate HTML file. Default: {}".format(outformat_html) )
parser.add_argument(      "--csv",                        action="store_true", help="Generate comma separated values file (CSV). Default: {}".format(outformat_csv) )
parser.add_argument("-t", "--table",                      action="store_true", help="Generate ODT with table instead of numbered list. Default: {}".format(odt_table) )

parser.add_argument("-s", "--src",         required=True, action="store",      help="Source commit hash, branch or tag name." )
parser.add_argument("-d", "--dst",         required=True, action="store",      help="Destination commit hash, branch or tag name." )
parser.add_argument("-a", "--gerrit-auth", required=True, action="store",      help="Gerrit user authentiction in form login:password." )

args = parser.parse_args()

if args.gerrit:
    gerrit = args.gerrit
if args.jira:
    jira = args.jira
if args.project:
    project = urllib.parse.quote(args.project)
if args.table:
    odt_table = args.table
if args.out:
    outfile_base = args.out
if args.ods:
    outformat_ods = args.ods
if args.odt:
    outformat_odt = args.odt
if args.html:
    outformat_html = args.html
if args.csv:
    outformat_csv = args.csv
if args.gerrit_auth:
    gerrit_auth = args.gerrit_auth.split(":")
    if len(gerrit_auth) != 2:
        sys.exit("ERROR: Gerrit auth is missing.\nTry: {} --help".format(os.path.basename(sys.argv[0])))

if args.src:
    src_commit = urllib.parse.quote(args.src)
if args.dst:
    dst_commit = urllib.parse.quote(args.dst)
if args.dst:
    dst_commit = urllib.parse.quote(args.dst)

print("gerrit: {}".format(gerrit))
print("project: {}".format(project))

print("src_commit: {}".format(src_commit))
print("dst_commit: {}".format(dst_commit))

if not (outformat_ods or outformat_odt or outformat_html or outformat_csv):
    sys.exit("ERROR: Out format is missing.\nTry: {} --help".format(os.path.basename(sys.argv[0])))

# Print error mesage
# Terminate script if exit_on_error == True
def perror_exit(err_msg):
    print(err_msg)
    if exit_on_error:
        sys.exit(err_msg)

# Return (Change-Id, Issues)
def find_cid_issues(text):
    issues  = ""
    cid     = ""
    cpat    = re.compile("^Change-Id: I[a-z0-9]*$")
    bpat    = re.compile("^bug:[ ]*[A-Z]*[0-9]*-[0-9]*$", re.IGNORECASE)
    tpat    = re.compile("^task:[ ]*[A-Z]*[0-9]*-[0-9]*$", re.IGNORECASE)
    for msg in text:
        if cpat.match(msg):
            cid = msg[11:].strip()
        n = 0
        if bpat.match(msg):
            n = 4
        else:
            if tpat.match(msg):
                n = 5
        if n > 0:
            issues += " {}".format(msg[n:].strip())
    return cid, issues.strip()

def generate_odf_table(doc, commit_list, numbering = True, with_border = False):
    # Nice formating
    width_gerrit = Style(name="WGerrit", family="table-column")
    width_gerrit.addElement(TableColumnProperties(columnwidth="9cm"))
    doc.automaticstyles.addElement(width_gerrit)
    width_issues = Style(name="WIssues", family="table-column")
    width_issues.addElement(TableColumnProperties(columnwidth="3cm"))
    doc.automaticstyles.addElement(width_issues)
    border = Style(name="TBorder", family="table-cell", parentstylename="Standard")
    if with_border:
        border.addElement(TableCellProperties(border="0.5pt solid #000000"))
    doc.automaticstyles.addElement(border)
    # Table
    table = Table(name="data")
    # Columns' formatting
    tcolumn = TableColumn()
    table.addElement(tcolumn)
    tcolumn = TableColumn(stylename = width_gerrit)
    table.addElement(tcolumn)
    tcolumn = TableColumn(stylename = width_issues)
    table.addElement(tcolumn)
    tcolumn = TableColumn()
    table.addElement(tcolumn)
    # Create table rows/cells
    NN = 0
    for commit in commit_list:
        NN += 1
        tr = TableRow()
        # cell: number
        if numbering:
            tc = TableCell(valuetype = 'float', value=NN, stylename = border)
        else:
            tc = TableCell(valuetype = 'string', stylename = border)
            tc.addElement(P(text=NN))
        tr.addElement(tc)
        # cell: gerrit link
        tc = TableCell(valuetype = 'string', stylename = border)
        p = P()
        p.addElement( A(type = "simple", href = "{}/q/{}".format(gerrit, commit['sha']), text = commit['sha']) )
        tc.addElement(p)
        tr.addElement(tc)
        # cell: issues list
        tc = TableCell(valuetype = 'string', stylename = border)
        for i in commit['issues'].split(' '):
            p = P()
            p.addElement( A(type = "simple", href = "{}/browse/{}".format(jira, i), text = i) )
            tc.addElement(p)
        tr.addElement(tc)
        # cell: short description
        tc = TableCell(valuetype = 'string', stylename = border)
        tc.addElement(P(text = commit['short']))
        tr.addElement(tc)
        # add row
        table.addElement(tr)
    return table

def generate_odf_list(doc, commit_list):
    # Nice numbering
    style = ListStyle(name = "List")
    numbers = ListLevelStyleNumber(level="1", stylename="Numbering", numsuffix=".", numformat='1')
    prop = ListLevelProperties(spacebefore="0.25in", minlabelwidth="0.25in")
    numbers.addElement(prop)
    style.addElement(numbers)
    doc.automaticstyles.addElement(style)
    # List
    textlist = List(stylename = style)
    for commit in commit_list:
        item = ListItem()
        p = P()
        # gerrit link
        # Gerrit abbrevs commit hash by 7 chars, we do the same
        p.addElement( A(type = "simple", href = "{}/q/{}".format(gerrit, commit['sha']), text = commit['sha'][:7]) )
        teletype.addTextToElement(p, " ")
        # issues list
        for i in commit['issues'].split(' '):
            p.addElement( A(type = "simple", href = "{}/browse/{}".format(jira, i), text = i) )
            teletype.addTextToElement(p, " ")
        # short description
        teletype.addTextToElement(p, commit['short'])
        item.addElement(p)
        textlist.addElement(item)
    return textlist

#############################################################################

commit_list = []

print("Collecting data from Gerrit...")

repeat     = True
next_start = ""
NN         = 0

query      = "plugins/gitiles/{}/+log/{}..{}".format(project, dst_commit, src_commit)
while repeat:
    url = "{}/a/{}/".format(gerrit, query)
    query_args = dict(format="JSON")
    if len(next_start) > 0:
        query_args["s"] = "{}".format(next_start)

    # gerrit_auth[0] = username
    # gerrit_auth[1] = password
    response = requests.get(url, params=(query_args), auth=(gerrit_auth[0], gerrit_auth[1]))

    #print(response.text)

    gerrit_prefix = ")]}'\n"
    if not response.text.startswith(gerrit_prefix):
        perror_exit("ERROR: This is not Gerrit REST API response")

    commit_logs = json.loads( response.text.replace(")]}'\n", "", 1) )

    for commit in commit_logs['log']:
        sha     = commit['commit']
        message = commit['message'].split('\n')
        short   = message[0].replace('"', "'")
        (cid, issues)  = find_cid_issues(message)
        if len(cid) < 1 or len(issues) < 1:
            perror_exit("ERROR: Either 'Change-Id:' or Issues list not found for commit {}".format(sha))

        NN += 1
        print("\rCommits: {} ".format(NN), end = "")
        commit_list.append({'sha':sha, 'cid':cid, 'issues':issues, 'short':short})

    if "next" in commit_logs:
        next_start = commit_logs['next']
        repeat = True
    else:
        next_start = ""
        repeat = False

print(" Done")

#############################################################################
# Iterate over changes to get change info
# This is time consuming
#
# The code is commented out and kept here for further investigation

#NN         = 0

#query      = "changes/{}~{}~".format(project, src_commit)
#for commit in commit_list:
    #url = "{}/a/{}{}".format(gerrit, query, commit['cid'])
    #response = requests.get(url, auth=(gerrit_auth[0], gerrit_auth[1]))

    ##print(response.text)

    #gerrit_prefix = ")]}'\n"
    #if not response.text.startswith(gerrit_prefix):
        #perror_exit("ERROR: This is not Gerrit REST API response")

    #change_log = json.loads( response.text.replace(")]}'\n", "", 1) )
    #commit['change'] = change_log['_number']

    ##print(change_log)

    #NN += 1
    #print("\rChanges: {} ".format(NN), end = "")

    #if NN > 16:
        #break

#print(" Done")

#############################################################################
if outformat_ods:
    print("Save data in ODS: {} ...".format(outfile_ods))
    doc = OpenDocumentSpreadsheet()
    table = generate_odf_table(doc, commit_list)
    doc.spreadsheet.addElement(table)
    doc.save(outfile_ods, False)
    print("Done")

#############################################################################
if outformat_odt:
    print("Save data in ODT({}): {} ...".format("table" if odt_table else "list", outfile_odt))
    doc = OpenDocumentText()
    if odt_table:
        odt_contents = generate_odf_table(doc, commit_list, numbering=False, with_border=True)
    else:
        odt_contents = generate_odf_list(doc, commit_list)
    doc.text.addElement(odt_contents)
    doc.save(outfile_odt, False)
    print("Done")

#############################################################################
if outformat_html:
    print("Save data in HTML: {} ...".format(outfile_html))

    NN = 0
    html_start = ['<!DOCTYPE html>\n',
                '<html lang="en">\n',
                '<head>\n',
                '<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>\n',
                '</head>\n',
                '<body>\n',
                '<table border="1" cellspacing="1">\n' ]
    html_end = [ '</table>\n',
                '</body>\n',
                '</html>\n' ]

    f = open(outfile_html, 'w')
    f.write("".join(html_start))
    for commit in commit_list:
        NN += 1
        jissues = []
        for i in commit['issues'].split(' '):
            jissues.append('<a href="{}/browse/{}">{}</a>'.format(jira, i, i))
        line = '<tr><td>{}</td><td><a href="{}/q/{}">{}</a></td><td>{}</td><td>{}</td></tr>\n'.format(NN, gerrit, commit['sha'], commit['sha'], '<br>'.join(jissues), commit['short'])
        f.write(line)
    f.write("".join(html_end))
    f.close()
    print("Done")

#############################################################################
# Collumn separator is ','
# Issues in the collumn separated by the ';'
if outformat_csv:
    print("Save data in CSV: {} ...".format(outfile_csv))

    NN = 0

    f = open(outfile_csv, 'w')
    for commit in commit_list:
        NN += 1
        jissues = []
        jlinks  = []
        for i in commit['issues'].split(' '):
            jissues.append('{}'.format(i))
            jlinks.append('{}/browse/{}'.format(jira, i))
        line = '{},{}/q/{},{},{},"{}"\n'.format(NN, gerrit, commit['sha'], ';'.join(jissues), ';'.join(jlinks), commit['short'])
        f.write(line)
    f.close()
    print("Done")
