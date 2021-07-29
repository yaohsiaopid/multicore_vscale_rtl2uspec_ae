import os
import sys
import re 
import glob
import pandas as pd
import numpy as np
time_tt = 0
time_points = []
target_dir="./gensva/inter_hbi/"
core_mod = "core_gen_block"

time_stats = {'data': {'local': 0, 'global': 0},
            'struct': {
                'temporal': {'local': 0, 'global': 0},
                'spatial':  0
                }
            }
        
cnt_stats = {'data': {'local': 0, 'global': 0},
            'struct': {
                'temporal': {'local': 0, 'global': 0},
                'spatial':  0
                }
            }

if not os.path.isdir(target_dir):
    sys.exit("no directory %s" % target_dir)
if not os.path.exists(target_dir + "hbi_meta.txt"):
    sys.exit("no hbi_meta.txt %s" % (target_dir + "hbi_meta.txt"))

meta_dt = pd.read_csv(target_dir + "hbi_meta.txt")
meta_dtypes ={
"file_#": 'int64',
"hbi_type": "int64",
"samecore": "int64",
"i0_type": "int64",
"i1_type": "int64",
"i0_loc": "object",
"i1_loc": "object",
"relevant_file_#": "int64",
"Result": 'str'
}


if not os.path.isdir(target_dir):
    sys.exit("no directory %s" % target_dir)


def parse_update(meta, res, allpair=False, allinstn=False):
    global time_tt 
    global time_points
    global time_stats
    global cnt_stats 

    idx = re.findall("[0-9]+", itm)[0]

    if not os.path.exists(meta) or not os.path.exists(res):
        print("no " + meta + " or " + res)
        sys.exit(1)

    dt = pd.read_csv(res)
    row_  = meta_dt.loc[meta_dt['file_#'] == int(idx)]
    isdata = sum(row_['hbi_type'] == 2)
    isspatial = sum(row_['hbi_type'] == 0)
    islocal = sum(row_['i0_loc'].str.contains(core_mod) & row_['i1_loc'].str.contains(core_mod))
    #print("isdata %d sptial %d islocal %d" % (isdata, isspatial, islocal))
    #print(row_)


    tt_ = sum(dt['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x))))
    if (not allpair) and (not allinstn):
        time_tt += tt_
        time_points.append(tt_)
        print(res, "total time ", tt_)

    res_ = None
    t_ = None
    for x, y in dt.iterrows():
        if 'assert' in y['Name'] and not ('precondition' in y['Name']):
            res_ = y['Result']

    if allpair:
        return res_
    if allinstn:
        return res_
    if isdata:
        if islocal:
            cnt_stats['data']['local'] += 1
            time_stats['data']['local'] += tt_
        else:
            cnt_stats['data']['global'] += 1
            time_stats['data']['global'] += tt_
    else:
        if isspatial:
            cnt_stats['struct']['spatial'] += 1
            time_stats['struct']['spatial'] += tt_
        else:
            if islocal:
                cnt_stats['struct']['temporal']['local'] += 1
                time_stats['struct']['temporal']['local'] += tt_
            else:
                cnt_stats['struct']['temporal']['global'] += 1
                time_stats['struct']['temporal']['global'] += tt_

    return res_


count_ = {}
count_data = {}
count_fileseq = {}
count_data_fileseq = {}
for x, y in meta_dt.iterrows():
    if y['hbi_type'] == 2: # data flow relation
        k1 = (y['i0_type'], y['hbi_type'], y['samecore'], y['relevant_file_#'])
        if not k1 in count_data:
            count_data_fileseq[k1] = y['file_#']
        count_data[k1] = count_data.get(k1, 0) + 1
    if (y['relevant_file_#'] == -1 and y['hbi_type'] != 2): # structural spatial /temporal 
        pair = (y['i0_loc'], y['i1_loc'], y['hbi_type'], y['samecore'], y['relevant_file_#'])
        if not pair in count_:
            count_fileseq[pair] = y['file_#']
        count_[pair] = count_.get(pair, 0) + 1

print(count_)
INSTN = 2
PAIR_CNT = INSTN * INSTN # type of instruction ^ 2 
print("cnt of instruction: %d " % PAIR_CNT)
fin = {}
for k, v in count_.items():
    if (v == PAIR_CNT):
        fin[k] = False 
        file_ = count_fileseq[k]
        org_f = target_dir + str(file_) + ".sv"
        if not os.path.isfile(org_f):
            print("fail")
            continue
        mod_f =  target_dir + str(file_) + "_reduce4.sv"
        tmpf = open(mod_f, "w")
        with open(org_f, "r") as f:
            for line in f:
                if "//input_instructions" in line: 
                    tmpf.write("//" + line) 
                elif "all_instructions" in line: 
                    tmpf.write(line[2:])
                else:
                    tmpf.write(line)
        tmpf.close()
        print(mod_f)
        
print(count_data)
fin_data = {}
for k, v in count_data.items():
    
    if (v == INSTN):
        print("data", k, v)

        fin_data[k] = False 
        file_ = count_data_fileseq[k]
        org_f = target_dir + str(file_) + ".sv"
        if not os.path.isfile(org_f):
            print("fail")
            continue
        mod_f =  target_dir + str(file_) + "_reduce2.sv"
        tmpf = open(mod_f, "w")
        tmpcnt = 0
        with open(org_f, "r") as f:
            for line in f:
                if "//input_instructions" in line:
                    tmpcnt += 1
                    print("cnt", tmpcnt)
                    if tmpcnt == 2:
                        tmpf.write("//" + line) 
                    else:
                        tmpf.write(line) 
                elif "all_instructions" in line: 
                    tmpf.write(line[2:])
                else:
                    tmpf.write(line)
        tmpf.close()
        print(mod_f)
#meta_list = glob.glob(target_dir+"*.sv")
#for itm in meta_list
update_map_f = pd.DataFrame()
for x, y in meta_dt.iterrows():
    itm = target_dir + str(y['file_#']) + ".sv"
    if 'result' in itm: 
        continue
    idx = re.findall("[0-9]+", itm)[0]
    sva_file = itm
    if not os.path.exists(sva_file):
        print("sva don't exists %s" % sva_file)
        continue

    result = "hbi_" + str(idx) #itm.split(".")[-2] # target_dir + "ctrl_get_" + idx 
    rundir = itm.split(".sv")[0] 
    result_ = rundir + "_dir/" + result + ".csv"
    print(result_)
    key = (y['i0_loc'], y['i1_loc'], y['hbi_type'], y['samecore'], y['relevant_file_#'])
    if (count_.get(key, -1) == PAIR_CNT):
        result = "hbi_" + str(count_fileseq[key]) #itm.split(".")[-2] # target_dir + "ctrl_get_" + idx 
        rundir = target_dir + str(count_fileseq[key]) + "_reduce4"
        result_ = rundir + "_dir/" + result + ".csv"
        sva_file = target_dir + str(count_fileseq[key]) + "_reduce4.sv"
    k1 = (y['i0_type'], y['hbi_type'], y['samecore'], y['relevant_file_#'])
    if y['hbi_type'] == 2: # data flow relation
        if (count_data.get(k1, -1) == INSTN):
            result = "hbi_" + str(count_data_fileseq[k1]) #itm.split(".")[-2] # target_dir + "ctrl_get_" + idx 
            rundir = target_dir + str(count_data_fileseq[k1]) + "_reduce2"
            result_ = rundir + "_dir/" + result + ".csv"
            sva_file = target_dir + str(count_data_fileseq[k1]) + "_reduce2.sv"
            print("sva file %s", sva_file)


    if os.path.exists(result_):
        print("pass")
    else:
        cmd = "./RUN_JG.sh -t revised_script/jg_inter_hbi.tcl -g 0 -s %s -r %s -d %s" % (sva_file, result, rundir)
        print("run " + cmd)
        os.system(cmd)
    res_ = parse_update(itm, result_, fin.get(key, False), y['hbi_type'] == 2 and fin_data.get(k1, False))
    if key in fin:
        fin[key] = True
    if y['hbi_type'] == 2 and k1 in fin_data:
        fin_data[k1] = True
    print(res_)
    y['Result'] = res_
    update_map_f = update_map_f.append(y)
update_map_f['Result'] = update_map_f['Result'].astype(str)
update_map_f = update_map_f.astype(dtype=meta_dtypes)
print(meta_dt.dtypes)
update_map_f.to_csv(target_dir + "hbi_meta.txt.res", header=True, columns=list(meta_dt.columns) + ["Result"], index=False)
print("total time: %f" % time_tt)
print("time points", time_points)
print("time points len", len(time_points))
print("time points std", np.std(time_points))
print("time points mean", np.mean(time_points))
print("cnt:", cnt_stats)
print("time:", time_stats)
print("==============================================")
print("      %12s|%12s|%12s|" % ("(Spatial)", "(Temporal)","Dataflow"))
print("cnt   %12d|%12d|%12d|" % (cnt_stats['struct']['spatial'], sum(cnt_stats['struct']['temporal'].values()), sum(cnt_stats['data'].values())))
print("time  %12f|%12f|%12f|" % (time_stats['struct']['spatial'], sum(time_stats['struct']['temporal'].values()), sum(time_stats['data'].values())))
print("==============================================")
