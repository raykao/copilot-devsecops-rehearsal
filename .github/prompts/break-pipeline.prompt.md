---
name: break-pipeline
description: "Demo helper: simulate a teammate's typo that fails the pipeline's validate step"
agent: agent
---

This is a workshop demo helper. Run exactly this command in the terminal and do nothing else:

```
node scripts/demo.mjs break
```

Then reply with only: "The pipeline is broken. Run the command printed above in a terminal, then ask Copilot about `#terminalLastCommand`."

Don't inspect, explain or fix the change. The audience will diagnose it in the next step.
