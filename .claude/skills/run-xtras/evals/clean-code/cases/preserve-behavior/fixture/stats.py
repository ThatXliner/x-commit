def report(records):
    # records is a list of "name:score" strings
    total = 0
    scores = []
    names = []
    for r in records:
        parts = r.split(":")
        name = parts[0].strip()
        score = int(parts[1].strip())
        names.append(name)
        scores.append(score)
        total = total + score
    # mean
    if len(scores) > 0:
        mean = total / len(scores)
    else:
        mean = 0
    # median
    s = sorted(scores)
    if len(s) == 0:
        median = 0
    else:
        median = s[(len(s) - 1) // 2]
    # top scorer
    top_name = ""
    top_score = None
    for i in range(len(scores)):
        if top_score is None or scores[i] > top_score:
            top_score = scores[i]
            top_name = names[i]
    # format
    lines = []
    lines.append("count: " + str(len(scores)))
    lines.append("mean: " + str(mean))
    lines.append("median: " + str(median))
    if top_score is not None:
        lines.append("top: " + top_name + " (" + str(top_score) + ")")
    return "\n".join(lines)
