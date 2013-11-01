#!/usr/bin/env python
from __future__ import division

import os
import sys
import datetime
from time import time
from optparse import OptionParser
import sqlite3

D2n_dic = dict(A=0, T=3, C=2, G=1, a=0, t=3, c=2, g=1)
n2D_dic = {0:'A', 3:'T', 2:'C', 1:'G', 0:'a', 3:'t', 2:'c', 1:'g'}

def print_usage():
    print '''
%s: Index DB for MFEprimer-2.0

Usage:

    %s -f human.genomic -k 9 -o index_db_name

Author: Wubin Qu <quwubin@gmail.com>
Last updated: 2012-9-28
    ''' % (os.path.basename(sys.argv[0]), os.path.basename(sys.argv[0]))

def optget():
    '''parse options'''
    parser = OptionParser()
    parser.add_option("-f", "--file", dest = "filename", help = "DNA file in fasta to be indexed")
    parser.add_option("-k", "--k", dest = "k", type='int', help = "K mer , default is 9", default = 9)
    parser.add_option("-o", "--out", dest = "out", help = "Index db file name")

    (options, args) = parser.parse_args()

    if not options.filename:
        print_usage()
        exit()

    if not options.out:
        options.out = options.filename + '.sqlite3.db'

    return options

def parse_fasta_format(fh):
    '''
    A Fasta-format Parser return Iterator
    '''
    # Remove the comment and blank lines before the first record
    while True:
        line = fh.readline()
        if not line: return # Blank line

        line = line.strip()

        if line.startswith('>'):
            break

    while True:
        if not line.startswith('>'):
            raise ValueError("Records in Fasta files should start with '>' character")

        id, sep, desc = line[1:].partition(' ')

        seq_lines = []
        line = fh.readline()
        while True:
            if not line: break

            line = line.strip()

            if line.startswith('>'):
                break

            if not line:
                line = fh.readline()
                continue

            seq_lines.append(line.replace(' ', '').replace("\r", ''))
            line = fh.readline()

        yield (id, desc, ''.join(seq_lines))

        if not line: return

    assert False, 'Should not reach this line'

def get_memory_percent():
    '''Print Memory information'''
    import os
    try:
        import psutil
        return psutil.virtual_memory().percent
    except:
        print '''psutil module needed.

    You can download and install it from here: http://code.google.com/p/psutil/
    '''
        exit()

def insert_db(conn, mer_count, plus, minus):
    for mer_id in xrange(mer_count):
        conn.execute("insert into pos (mer_id, plus, minus) values (?, ?, ?)", \
                [mer_id, plus[mer_id], minus[mer_id]])

    conn.commit()

def update_db(conn, mer_count, plus, minus):
    for mer_id in xrange(mer_count):
        (plus_data, minus_data) = conn.execute("select plus, minus from pos where mer_id=?", [mer_id]).fetchone()
        if plus_data:
            if plus[mer_id]:
                plus_data += ';%s' % plus[mer_id]
            else:
                pass
        else:
            plus_data = plus[mer_id]

        if minus_data:
            if minus[mer_id]:
                minus_data += ';%s' % minus[mer_id]
            else:
                pass
        else:
            minus_data = minus[mer_id]

        conn.execute("update pos set plus=?, minus=? where mer_id=?", \
                [plus_data, minus_data, mer_id])

    conn.commit()

def baseN(num, b):
    '''convert non-negative decimal integer n to
    equivalent in another base b (2-36)'''
    return ((num == 0) and  '0' ) or ( baseN(num // b, b).lstrip('0') + "0123456789abcdefghijklmnopqrstuvwxyz"[num % b])

def int2DNA(num, k):
    seq = baseN(num, 4)
    return 'A' * (k-len(seq)) + (''.join([n2D_dic[int(base)] for base in seq]))

def DNA2int_2(seq):
    '''convert a sub-sequence/seq to a non-negative integer'''
    plus_mer = 0
    minus_mer = 0
    length = len(seq) - 1
    for i, letter in enumerate(seq):
        plus_mer += D2n_dic[letter] * 4 ** (length - i)
        minus_mer += (3 - D2n_dic[letter]) * 4 ** i

    return plus_mer, minus_mer

def DNA2int(seq):
    '''convert a sub-sequence/seq to a non-negative integer'''
    plus_mer = 0
    length = len(seq) - 1
    for i, letter in enumerate(seq):
        plus_mer += D2n_dic[letter] * 4 ** (length - i)

    return plus_mer

def index(filename, k, dbname):
    ''''''
    start = time()

    mer_count = 4**k

    conn = sqlite3.connect(dbname)
    cur = conn.cursor()
    cur.executescript('''
    drop table if exists pos;
    create table pos(
    mer_id integer primary key,
    plus text,
    minus text
    );''')

    plus = ['']*mer_count
    minus = ['']*mer_count

    is_empty = False
    is_db_new = True

    for record_id, record_desc, fasta_seq in parse_fasta_format(open(filename)):
        is_empty = False
        print record_id

        #print 'Time used: ', time() - start

        #plus_mer_list = [''] * mer_count
        #minus_mer_list = [''] * mer_count
        plus_mer_list = {}
        minus_mer_list = {}

        for i in xrange(len(fasta_seq)-k + 1):
            #start = time()
            kmer = fasta_seq[i:(i+k)]
            #print kmer, i

            try:
                plus_mer_id, minus_mer_id = DNA2int_2(kmer)
            except:
                # Skip the unrecognized base, such as 'N'
                continue

            if plus_mer_list.has_key(plus_mer_id):
                plus_mer_list[plus_mer_id] += ',%i' % (i+k-1)
            else:
                plus_mer_list[plus_mer_id] = str(i+k-1)

            if minus_mer_list.has_key(minus_mer_id):
                minus_mer_list[minus_mer_id] += ',%i' % (i)
            else:
                minus_mer_list[minus_mer_id] = str(i)


        #print 'Index time used: ', time() - start
        #start = time()
        for mer_id, pos in plus_mer_list.items():
            if plus[mer_id]:
                plus[mer_id] += ';%s:%s' % (record_id, pos)
            else:
                plus[mer_id] = '%s:%s' % (record_id, pos)

        for mer_id, pos in minus_mer_list.items():
            if minus[mer_id]:
                minus[mer_id] += ';%s:%s' % (record_id, pos)
            else:
                minus[mer_id] = '%s:%s' % (record_id, pos)

        #print 'Merge time used: ', time() - start

        memory_percent = get_memory_percent()
        if memory_percent > 70:
            if is_db_new:
                insert_db(conn, mer_count, plus, minus)
                is_db_new = False
            else:
                update_db(conn, mer_count, plus, minus)

            # Empty the container
            plus = ['']*mer_count
            minus = ['']*mer_count
            is_empty = True

            print 'Empty plus and minus due to the memory: %s.' % memory_percent

    if not is_empty:
        if is_db_new:
            insert_db(conn, mer_count, plus, minus)
        else:
            update_db(conn, mer_count, plus, minus)

    print "Time used: %s" % str(datetime.timedelta(seconds=(time() - start)))
    print 'Done.'

def main():
    '''main'''
    options = optget()
    index(options.filename, options.k, options.out)

if __name__ == "__main__":
    main()
