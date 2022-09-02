# Machine learning decision tree analysis for PATRIC feature identification

# Creating the environment
```
cd "Figure 2/ml"
./bootstrap_env.sh
```

# Launching jupyter
```
cd "Figure 2/ml"
conda activate strain_library
jupyter notebook
```

1. Your browser should open with a Jupyter file selection page.
1. Open the file "notebook.ipynb"
1. At this point, you can see all the saved interactive, zoomable, hoverable plots stored inside the notebook.

# Re-running the entire notebook

1. From the menu bar, click "Cell...Run All"

# Running inside Google Colab

This is just another way to run Jupyter so that you can share like a Google Doc.  You kind of need to know what you're doing to make this work.

```
conda activate strain_library

jupyter notebook \
    --NotebookApp.allow_origin='https://colab.research.google.com' \
    --port=8888 \   
    --no-browser \
    --NotebookApp.port_retries=0
```

See also Google Colab notebooks:
1. First version: https://colab.research.google.com/drive/1EkWVxK55K3ZJSb1CUGA9_czx2nPO3x0R#scrollTo=6KPrdVxf5SGb
2. For the paper: https://colab.research.google.com/drive/16eckWUzRIbOSqWgr2L4mHFt_lPfusiyU
