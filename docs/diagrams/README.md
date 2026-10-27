# Diagrams

The site diagrams are SVG files in `site/public/diagrams/`. Python scripts in `src/` generate them, so a label change is a one-line edit and a re-run.

## Regenerate

You need Python 3, Microsoft Edge (to render the PNG preview), and the Azure public service icon set. The icons are not in the repo.

```powershell
$env:DIAGRAM_ICONS = 'C:\path\to\icons'   # contains az\Azure_Public_Service_Icons\Icons and github.svg
$env:DIAGRAM_OUT = "$env:TEMP\diagram-out"
cd docs\diagrams\src
python gen03.py
```

Copy the SVG you want from `DIAGRAM_OUT` to `site/public/diagrams/`. Commit the SVG only, not the PNG.

| Script | Diagram |
| --- | --- |
| `gen02.py` to `gen12.py` | `diagram-02` to `diagram-12` |
| `genP1.py` | `diagram-13-pipeline-who-runs-what` |
| `genP2.py` | `diagram-14-pipeline-sign-in` |

`diagram-01` is edited by hand in its SVG.

## Use one on a page

```mdx
import Diagram from "../../../components/Diagram.astro";

<Diagram name="diagram-13-pipeline-who-runs-what" alt="..." caption="..." wide />
```
