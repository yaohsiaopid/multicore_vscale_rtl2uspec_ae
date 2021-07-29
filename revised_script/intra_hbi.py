import os
import sys
import re 
import glob
import pandas as pd
import numpy as np
time_tt = 0
time_points = []
time_points_delta = []
target_dir="./gensva/intra_hbi/"
core_mod="core_gen_block[0].vscale"
eventual = 0 
time_stats = {'local': 0, 'global': 0, 'instn_eventual': 0, 'remote_eventual': 0}
cnt_stats = {'local': 0, 'global': 0, 'instn_eventual': 0, 'remote_eventual': 0}
pass_cnt_stats = {'local': 0, 'global': 0}
if not os.path.isdir(target_dir):
    sys.exit("no directory %s" % target_dir)

def parse_update(meta, res, res_eventual, idx):
    global time_tt 
    global time_points
    global time_stats
    global eventual
    global cnt_stats 
    global target_dir

    if not os.path.exists(meta) or not os.path.exists(res):
        print("no " + meta + " or " + res)
        sys.exit(1)

    sva_result = {}
    sva_result_t = {}
    dt = pd.read_csv(res)
    print(sum(dt['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x)))))

    for x, y in dt.iterrows():
        sva_result[y['Name'].split(".")[1]] = y['Result']
        sva_result_t[y['Name'].split(".")[1]] = float(re.sub('[^0-9.]', '', y['Time']))
        time_tt += float(re.sub('[^0-9.]', '', y['Time']))
    print('meta: ' + meta)
    map_f = pd.read_csv(meta, header=None, delimiter=";")
    map_f[3] = None
    update_map_f = pd.DataFrame()
    
    cnt_m = 0

    for x, line in map_f.iterrows():
        ctrl_ = None
        num = str(line[1])
        if line[0] == 'm':
            ctrl_ = 'MEM_A_' + num
        else:
            ctrl_ = 'AFIX_' + num
        res = sva_result.get(ctrl_, "NaN")
        if line[0] == 'm':
            if res == "proven": # check WEN == 1 is proven
                line[3] = "updated"
                ### TODO run 
                if not core_mod in line[2]:
                    remote_prefix = "eventual_remote_%d_%s" % (cnt_m, idx)
                    res_csv_remote = target_dir + remote_prefix + "_dir/" + remote_prefix +  ".csv"

                    if os.path.exists(res_csv_remote):
                        print("pass %s" % res_csv_remote)
                    else:
                        cmd = "./RUN_JG.sh -t revised_script/jg_intra_hbi.tcl -g 0 -s %s -r %s -d %s" % (target_dir + remote_prefix + ".sv", remote_prefix, target_dir + remote_prefix) 
                        print("TO run " + cmd)
                        print("goal: " + res_csv_remote)
                        os.system(cmd)
                        # "eventual_remote_%d_%d.sv" % (cnt_m, idx)
                    tmpdf = pd.read_csv(res_csv_remote)
                    t_ = sum(tmpdf['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x))))
                    time_tt += t_ #sum(dt['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x))))
                    time_stats['remote_eventual'] += t_
                    cnt_stats['remote_eventual'] += 1
                    for _, tmprow in tmpdf.iterrows():
                        if 'assert' in tmprow['Name'] and (not 'precondition' in tmprow['Name']):
                            if not tmprow['Result'] == "proven":
                                line[3] = "fixed" 
                                print("fail remote " + tmprow + res_csv_remote)
                            else:
                                print("success " + res_csv_remote)
         
            else:
                line[3] = "fixed"
        else:
            if res == "proven":
                line[3] = "fixed"
            else:
                line[3] = "updated"

        pred = sva_result_t.get(ctrl_ + ":precondition1", 0)
        pred_ = pred + sva_result_t.get(ctrl_, 0)
        time_points.append(pred_)
        if core_mod in line[2]:
            time_stats['local'] += pred_ #sva_result_t.get(ctrl_, 0)
            cnt_stats['local'] += 1
            pass_cnt_stats['local'] += (line[3] == "updated")
        else:
            time_stats['global'] += pred_ #sva_result_t.get(ctrl_, 0)
            cnt_stats['global'] += 1
            pass_cnt_stats['global'] += (line[3] == "updated")
        
        update_map_f = update_map_f.append(line)
    

    print("result at" + meta + ".res")
    update_map_f[1] = update_map_f[1].astype(int)
    update_map_f.to_csv(meta + ".res", sep=';', header=False, index=False)

    print("---------------------------")
    dt = pd.read_csv(res_eventual)
    print(sum(dt['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x)))))
    t_ = sum(dt['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x))))
    time_tt += t_ #sum(dt['Time'].apply(lambda x:  float(re.sub('[^0-9.]', '', x))))
    eventual += t_
    
    time_stats['instn_eventual'] += t_
    cnt_stats['instn_eventual'] += 1
    with open(meta + ".res", "a+") as f:

        for x, y in dt.iterrows():
            if "assert" in y['Name'] and (not "precondition" in y['Name']):
                f.write(y['Result'])
                time_points_delta.append(float(re.sub('[^0-9.]', '', y['Time'])))
                break
    print("=================================================")
    ### add eventual_remote_%d_%d.sv" % (cnt_m, idx)


meta_list = glob.glob(target_dir+"ever_update_*.txt")
for itm in meta_list:
    if 'result' in itm: 
        continue
    idx = re.findall("[0-9]", itm)[0]
    sva_file = target_dir + "ever_update_" + idx + ".sv"
    if not os.path.exists(sva_file):
        print("sva don't exists %s" % sva_file)
        continue

    result = "ever_update_" + idx #itm.split(".")[-2] # target_dir + "ctrl_get_" + idx 
    rundir = itm.split(".txt")[0] # target_dir + "ctrl_get_" + idx 
    result_csv = rundir + "_dir/" + result + ".csv"
    print(result_csv)
    if os.path.exists(result_csv):
        print("pass")
    else:
        cmd = "./RUN_JG.sh -t revised_script/jg_intra_hbi.tcl -g 0 -s %s -r %s -d %s" % (sva_file, result, rundir)
        print("run " + cmd)
        os.system(cmd)

    result = "eventual_" + idx #itm.split(".")[-2] # target_dir + "ctrl_get_" + idx 
    rundir = target_dir + "eventual_" + idx # itm.split(".txt")[0] + "eventual" # target_dir + "ctrl_get_" + idx 
    result_csv_eventual = rundir + "_dir/" + result + ".csv"
    sva_file = target_dir + "eventual_" + idx + ".sv"
    print(result_csv_eventual)

    if os.path.exists(result_csv_eventual):
        print("pass")
    else:
        cmd = "./RUN_JG.sh -t revised_script/jg_intra_hbi.tcl -g 0 -s %s -r %s -d %s" % (sva_file, result , rundir)
        print("run " + cmd)
        os.system(cmd)

    parse_update(itm, result_csv, result_csv_eventual, idx)

    #result + ".csv")
print("================================================== ")
print("Total time on intra-instruction HBI (sec) : %f" % time_tt)
cnt_ = 0
for k, v in cnt_stats.items():
    cnt_ += v
print("Total number of SVA evaluated: %d" % cnt_)
print("================================================== ")
#avg = (time_tt - sum(time_points))*1.0/len(time_points)
#print("avg assumption", avg)
#print(time_points + time_points_delta)
#print("time points std with delta", np.std(time_points + time_points_delta))
#time_points = np.array(time_points) + avg
#print("time points", time_points)
#print("time poitns sum", sum(time_points))
#print("time points len", len(time_points))
#print("time points std", np.std(time_points+avg))
#print("time points mean", np.mean(time_points+avg))
#print("time: ", time_stats)
print("cnt: ", cnt_stats)
print("pass cnt(ever update): ", pass_cnt_stats)
