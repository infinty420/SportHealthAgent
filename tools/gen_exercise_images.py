# AI 生成 —— 批量生成 3D 解剖风动作图（调用 image_generation 插件脚本，并行加速）
# 用法: bash tools/gen_exercise_images.sh <batch序号: 1|2>
# 产物: entry/src/main/resources/base/media/ex2_<id>.png
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

PLUGIN = Path("C:/Users/infinty/AppData/Roaming/kimi-desktop/daimon-share/daimon/runtime/kimi-code/home/plugins/managed/image_generation")
TOOL = PLUGIN / "scripts/image_generation_tool.py"
MEDIA = Path("C:/Users/infinty/Documents/SportHealthAgent/entry/src/main/resources/base/media")

STYLE = ("Fitness tutorial illustration for a workout app: a person demonstrating the exercise, "
         "clean light gray seamless studio background, soft lighting, full body visible, "
         "three-quarter view, polished 3D render style, no text")

# (id, 动作英文描述)
JOBS = [
    ("bb_squat", "performing a barbell back squat at the bottom position, barbell resting on upper trapezius, quadriceps and glutes highlighted"),
    ("bb_deadlift", "performing a barbell deadlift, hinged forward gripping the barbell at shin height, back flat, hamstrings and lower back highlighted"),
    ("bb_press", "performing a standing overhead barbell shoulder press, barbell pressed above head, shoulders highlighted"),
    ("db_bench", "performing a dumbbell bench press on a flat bench, two dumbbells lowered beside the chest, chest highlighted"),
    ("db_row", "performing a one-arm dumbbell row with one hand and knee supported on a bench, back muscles highlighted"),
    ("db_lunge", "performing a dumbbell lunge holding dumbbells at sides, front leg bent at 90 degrees, quadriceps and glutes highlighted"),
    ("db_lateral", "performing a standing dumbbell lateral raise with both arms lifted out to the sides at shoulder height, shoulders highlighted"),
    ("sm_bench", "performing a bench press on a Smith machine with guided bar rails, chest highlighted"),
    ("sm_squat", "performing a squat on a Smith machine with guided bar rails, quadriceps highlighted"),
    ("sm_press", "performing a seated shoulder press on a Smith machine, shoulders highlighted"),
    ("sm_hipthrust", "performing a hip thrust with upper back resting on a bench and a Smith machine bar across the hips, glutes highlighted"),
    ("cb_fly", "performing a cable fly standing in the middle of a cable crossover machine, arms sweeping inward, chest highlighted"),
    ("cb_pulldown", "performing a lat pulldown seated at a cable machine pulling the wide bar to the upper chest, lats highlighted"),
    ("cb_facepull", "performing a cable face pull with a rope attachment pulled toward the face, rear shoulders highlighted"),
    ("cb_pushdown", "performing a triceps rope pushdown at a cable station, elbows pinned to the sides, triceps highlighted"),
    ("bw_pushup", "performing a push-up on the floor at the bottom position, chest and triceps highlighted"),
    ("bw_pullup", "performing a pull-up hanging from a horizontal bar with chin above the bar, back and biceps highlighted"),
    ("bw_plank", "holding a forearm plank position on the floor, body in a straight line, core muscles highlighted"),
    ("bw_burpee", "performing a burpee, captured mid-jump with arms overhead, full body muscles highlighted"),
    ("bd_row", "performing a seated resistance band row pulling the band toward the torso, back highlighted"),
    ("bd_squat", "performing a resistance band squat standing on the band and holding it at shoulder height, quadriceps highlighted"),
    ("bd_lateral", "performing a resistance band lateral raise standing on the band, arms lifted to the sides, shoulders highlighted"),
    ("bd_glutebridge", "performing a resistance band glute bridge lying on the back with the band looped above the knees, hips lifted, glutes highlighted"),
    ("bb_curl", "performing a standing barbell bicep curl at the top contracted position, elbows pinned to the sides, biceps highlighted"),
    ("bb_reversecurl", "performing a standing reverse-grip barbell curl with overhand grip, forearms and brachioradialis highlighted"),
    ("db_curl", "performing a standing alternating dumbbell bicep curl with wrist supination, one dumbbell at the top, biceps highlighted"),
    ("db_wristcurl", "performing a seated dumbbell wrist curl with forearm resting on a bench and wrist hanging off the edge, forearm flexor muscles highlighted"),
    ("sm_closegrip", "performing a close-grip bench press on a Smith machine with hands shoulder-width apart, triceps highlighted"),
    ("bw_dips", "performing parallel bar dips at the bottom position with upright torso, triceps highlighted"),
    ("bw_crunch", "performing an abdominal crunch lying on the back with knees bent, shoulder blades lifted off the floor, upper abs highlighted"),
    ("bw_legraise", "performing a lying leg raise on the back with straight legs lifted vertically, lower abs highlighted"),
    ("bw_sideplank", "holding a side plank position supported on one forearm, body in a straight line, obliques highlighted"),
    ("bw_pushupplus", "performing a push-up plus at the top position with scapula protracted pushing the upper back toward the ceiling, serratus anterior highlighted"),
    ("bw_jumpingjack", "performing a jumping jack captured mid-air with legs spread and arms overhead clapping, full body highlighted"),
    ("bw_jumprope", "performing jump rope skipping mid-jump holding rope handles, calves and shoulders highlighted"),
    ("bw_mountainclimber", "performing mountain climbers in a plank position driving one knee toward the chest, abs and hip flexors highlighted"),
    # ==================== 第三批：扩充动作 ====================
    ("bb_decline", "performing a decline barbell bench press on a decline bench, barbell lowered to lower chest, chest highlighted"),
    ("bb_row", "performing a bent-over barbell row hinged forward at 45 degrees pulling the bar toward the belly, back highlighted"),
    ("bb_rdl", "performing a Romanian deadlift with barbell lowered to mid-shin, knees slightly bent, hamstrings and glutes highlighted"),
    ("bb_tbarrow", "performing a T-bar row with a landmine barbell, pulling the weighted end toward the chest, mid back highlighted"),
    ("bb_uprightrow", "performing a barbell upright row pulling the bar up to chest height with elbows high, side shoulders highlighted"),
    ("bb_sumo", "performing a sumo barbell squat with wide stance and toes pointed out, inner thighs and glutes highlighted"),
    ("bb_preacher", "performing a preacher curl with a barbell on a preacher bench, upper arms resting on the pad, biceps highlighted"),
    ("bb_closegrip", "performing a close-grip barbell bench press with hands shoulder-width apart, triceps highlighted"),
    ("bb_skullcrusher", "performing a lying triceps extension lowering a barbell toward the forehead on a flat bench, triceps highlighted"),
    ("db_incline", "performing an incline dumbbell bench press on a 45-degree incline bench, upper chest highlighted"),
    ("db_fly", "performing a dumbbell fly on a flat bench with arms opening in a wide arc, chest highlighted"),
    ("db_press", "performing a standing dumbbell overhead press, shoulders highlighted"),
    ("db_frontraise", "performing a dumbbell front raise lifting dumbbells forward to shoulder height, front shoulders highlighted"),
    ("db_rearfly", "performing a bent-over dumbbell rear delt fly hinged forward, rear shoulders highlighted"),
    ("db_arnold", "performing an Arnold press rotating dumbbells from palms-facing-in while pressing overhead, shoulders highlighted"),
    ("db_bulgarian", "performing a Bulgarian split squat with rear foot elevated on a bench holding dumbbells, quadriceps highlighted"),
    ("db_concentration", "performing a seated concentration curl with elbow braced against inner thigh, biceps highlighted"),
    ("db_hammer", "performing a hammer curl with neutral grip dumbbells, biceps and forearms highlighted"),
    ("db_overheadext", "performing an overhead dumbbell triceps extension lowering one dumbbell behind the head, triceps highlighted"),
    ("db_kickback", "performing a bent-over dumbbell triceps kickback with upper arm parallel to torso, triceps highlighted"),
    ("db_reversewrist", "performing a reverse wrist curl with forearm on bench palms down lifting the back of the hands, forearm highlighted"),
    ("db_farmerwalk", "performing a farmer's walk carrying two heavy dumbbells while walking upright, forearms and traps highlighted"),
    ("cb_seatedrow", "performing a seated cable row pulling the handle to the abdomen with upright torso, mid back highlighted"),
    ("cb_straightarm", "performing a straight-arm cable pulldown pushing the bar down toward the thighs, lats highlighted"),
    ("cb_underpulldown", "performing an underhand-grip lat pulldown pulling the bar to the upper chest, lats highlighted"),
    ("cb_curl", "performing a cable bicep curl at a low pulley station, biceps highlighted"),
    ("bw_backext", "performing a back extension on a 45-degree hyperextension bench raising the torso, lower back highlighted"),
    ("bw_reversecrunch", "performing a reverse crunch lying on the back curling knees toward the chest, lower abs highlighted"),
    ("bw_russiantwist", "performing a Russian twist seated leaning back rotating the torso side to side, obliques highlighted"),
    ("bw_deadbug", "performing a dead bug exercise lying on the back extending opposite arm and leg, core highlighted"),
    ("bw_hanglegraise", "performing a hanging leg raise on a pull-up bar lifting straight legs to horizontal, lower abs highlighted"),
    ("bw_jog", "jogging outdoors at an easy pace, mid-stride running pose, full body"),
    ("bw_walk", "brisk walking with active arm swing, upright posture, full body"),
    ("bw_hiit", "performing a HIIT high-knee sprint in place with knees driving up, full body muscles highlighted"),
    ("mc_chestpress", "performing a seated machine chest press pushing the handles forward, chest highlighted"),
    ("mc_pecfly", "performing a pec deck machine fly squeezing the pads together, chest highlighted"),
    ("mc_lateral", "performing a machine lateral raise with arms on the pads lifting to the sides, side shoulders highlighted"),
    ("mc_assistpullup", "performing an assisted pull-up on a machine kneeling on the pad, back highlighted"),
    ("mc_legpress", "performing a leg press on a 45-degree machine pushing the platform, quadriceps highlighted"),
    ("mc_legext", "performing a leg extension machine lifting the padded bar with the shins, quadriceps highlighted"),
    ("mc_legcurl", "performing a lying leg curl machine curling the padded bar toward the hips, hamstrings highlighted"),
    ("mc_standingcalf", "performing a standing calf raise on a machine with shoulders under the pads, calves highlighted"),
    ("mc_seatedcalf", "performing a seated calf raise machine with knees under the pad, calves highlighted"),
    ("mc_wristroller", "performing a wrist roller exercise rolling up a hanging weight with arms extended forward, forearms highlighted"),
    ("mc_elliptical", "using an elliptical trainer machine gliding with moving handles, full body"),
    ("mc_bike", "riding a stationary spinning bike seated pedaling, legs highlighted"),
    ("mc_stair", "using a stair climber machine stepping with upright posture, glutes and legs highlighted"),
    # ==================== 拉伸动作 ====================
    ("st_doorframe", "performing a doorway chest stretch with forearm against a door frame leaning forward, chest stretch"),
    ("st_crossshoulder", "performing a cross-body shoulder stretch pulling one arm across the chest, shoulder stretch"),
    ("st_reardelt", "performing a rear deltoid stretch pulling one arm across the upper body slightly bent forward"),
    ("st_childspose", "holding child's pose kneeling with arms extended forward on the floor, back relaxed"),
    ("st_backstretch", "performing a one-arm lat stretch holding a fixed bar and sitting back, lats stretch"),
    ("st_quad", "performing a standing quad stretch holding one ankle behind, quadriceps stretch"),
    ("st_hamstring", "performing a seated hamstring stretch reaching toward one extended leg, hamstrings stretch"),
    ("st_pigeon", "performing a pigeon pose with front leg bent across and torso leaning forward, glutes stretch"),
    ("st_calf", "performing a wall calf stretch in a lunge position pushing against a wall, calves stretch"),
    ("st_catcow", "performing a cat-cow stretch on hands and knees with rounded back, spine mobility"),
    ("st_sidebend", "performing a standing side bend stretch with one arm overhead leaning sideways, obliques stretch"),
    ("st_bicep", "performing a bicep stretch with arm extended back holding a fixed surface, biceps stretch"),
    ("st_tricep", "performing an overhead triceps stretch pressing the elbow behind the head, triceps stretch"),
    ("st_forearm", "performing a forearm stretch pressing the palm down with the other hand, forearm stretch"),
]


def run_one(job: tuple) -> str:
    ex_id, action = job
    out = MEDIA / f"ex2_{ex_id}.jpg"
    if (MEDIA / f"ex2_{ex_id}.png").exists() or out.exists():
        return f"[SKIP] {ex_id}"
    cmd = [
        sys.executable, str(TOOL), "generate",
        "--description", f"{STYLE}, {action}",
        "--size", "1024x1024", "--background", "opaque",
        "--output", str(out),
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=280)
        if proc.returncode == 0:
            return f"[OK] {ex_id}"
        return f"[FAIL] {ex_id}: {proc.stdout[-200:]} {proc.stderr[-200:]}"
    except Exception as e:
        return f"[FAIL] {ex_id}: {type(e).__name__}"


def main() -> None:
    batch = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    half = (len(JOBS) + 1) // 2
    jobs = JOBS[:half] if batch == 1 else JOBS[half:]
    with ThreadPoolExecutor(max_workers=2) as pool:
        for result in pool.map(run_one, jobs):
            print(result, flush=True)


if __name__ == "__main__":
    main()
