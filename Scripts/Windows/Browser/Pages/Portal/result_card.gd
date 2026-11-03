class_name ResultCard
extends PanelContainer


func configure(case: Dictionary, res: Dictionary) -> void:
	var right: bool = res["correct"]
	theme_type_variation = &"CardOk" if right else &"CardError"
	name = "Result_" + str(case["id"])
	%Name.text = case["name"]
	%Seal.text = Content.t("result.right") if right else Content.t("result.wrong")
	%Seal.theme_type_variation = &"LabelOk" if right else &"LabelError"
	var real := Content.label("verdict", case["real_verdict"])
	if case.get("real_type") != null:
		real += " — " + Content.label("type", case["real_type"])
	var your := Content.label("verdict", res["verdict"])
	if res["verdict"] == "malicious" and res["type"] != "":
		your += " — " + Content.label("type", res["type"])
	%Verdict.text = Content.t("result.your_verdict", [your, real])
	%Questionnaire.text = Content.t("result.questionnaire", [res["correct_questionnaire"], 4])
	%Explanation.text = str(case["explanation"])
