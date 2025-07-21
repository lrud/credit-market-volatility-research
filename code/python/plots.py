import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Common settings
critval = 1.959963984540054
pdf_width_inches = 7
pdf_height_inches = 4.2
png_dpi = 200

# Plotting function to avoid code repetition
def create_coefficient_plot(data_dict, var_name, y_axis_label_text, plot_title, plot_subtitle, 
                            output_filename_base, figures_path="."):
    df = pd.DataFrame(data_dict)
    df['ci_low'] = df['coef'] - critval * df['se']
    df['ci_high'] = df['coef'] + critval * df['se']

    qreg_df = df[df['model_type'] == 'QReg'].sort_values(by='x_plot_val')
    ols_df = df[df['model_type'] == 'OLS']

    fig, ax = plt.subplots(figsize=(pdf_width_inches, pdf_height_inches))

    # Quantile Regression
    ax.fill_between(qreg_df['x_plot_val'], qreg_df['ci_low'], qreg_df['ci_high'], 
                    color='maroon', alpha=0.15, label='QR 95% CI')
    ax.plot(qreg_df['x_plot_val'], qreg_df['coef'], color='maroon', linestyle='-', linewidth=1.5, 
            marker='D', markersize=7, label='QR Coef.')

    # OLS Regression
    if not ols_df.empty:
        ols_point = ols_df.iloc[0]
        ols_x_pos = ols_point['x_plot_val']
        ax.hlines(y=ols_point['coef'], xmin=ols_x_pos - 0.1, xmax=ols_x_pos + 0.1, 
                  color='darkblue', linestyle='-', linewidth=1.5)
        ax.hlines(y=ols_point['ci_low'], xmin=ols_x_pos - 0.1, xmax=ols_x_pos + 0.1, 
                  color='darkblue', alpha=0.7, linestyle='--', linewidth=1)
        ax.hlines(y=ols_point['ci_high'], xmin=ols_x_pos - 0.1, xmax=ols_x_pos + 0.1,
                  color='darkblue', alpha=0.7, linestyle='--', linewidth=1)
        ax.plot(ols_point['x_plot_val'], ols_point['coef'], color='darkblue', 
                marker='s', markersize=7, label='OLS Coef.', linestyle='None')
        
        if "implied_vol" in output_filename_base:
            mlabformat_str = "{:.4f}"
            mlab_x_offset = 0.15 
        elif "neg_log_ret" in output_filename_base:
            mlabformat_str = "{:.2f}"
            mlab_x_offset = -0.15
        else:
            mlabformat_str = "{:.3f}"
            mlab_x_offset = 0.15

        ax.text(ols_point['x_plot_val'] + mlab_x_offset, ols_point['coef'], 
                mlabformat_str.format(ols_point['coef']), 
                verticalalignment='center', horizontalalignment='left' if mlab_x_offset > 0 else 'right',
                fontsize=8, color='black')

    all_y_values = pd.concat([qreg_df['ci_low'], qreg_df['ci_high'], 
                              ols_df['ci_low'] if not ols_df.empty else pd.Series(dtype='float64'), 
                              ols_df['ci_high'] if not ols_df.empty else pd.Series(dtype='float64')])
    min_y = all_y_values.min()
    max_y = all_y_values.max()
    padding = (max_y - min_y) * 0.05
    ax.set_ylim(min_y - padding, max_y + padding)

    ax.set_xticks([1, 2, 3])
    ax.set_xticklabels(["Q25", "Q50/OLS", "Q75"], fontsize=9)
    ax.set_xlim(0.7, 3.3)
    ax.tick_params(axis='x', which='major', length=0)

    ax.set_title(plot_title, fontsize=11, loc='center', pad=15)
    fig.text(0.5, 0.91, plot_subtitle, ha='center', fontsize=9, color='dimgray')
    ax.set_ylabel(y_axis_label_text, fontsize=9)
    
    ax.yaxis.grid(True, linestyle=':', color='lightgrey', alpha=0.7)

    handles, labels = ax.get_legend_handles_labels()
    desired_order = ['QR Coef.', 'QR 95% CI', 'OLS Coef.']
    if not ols_df.empty:
        ordered_handles = []
        ordered_labels = []
        for lbl in desired_order:
            if lbl in labels:
                idx = labels.index(lbl)
                ordered_handles.append(handles[idx])
                ordered_labels.append(labels[idx])
        ax.legend(ordered_handles, ordered_labels, loc='upper right', bbox_to_anchor=(1, 0.95), 
                  fontsize=8, frameon=False, ncol=1)
    else:
        ax.legend(handles, labels, loc='best', fontsize=8, frameon=False, ncol=1)

    ax.set_facecolor('white')
    fig.set_facecolor('white')
    for spine in ['top', 'right']:
        ax.spines[spine].set_visible(False)
    for spine in ['left', 'bottom']:
        ax.spines[spine].set_color('black')
        ax.spines[spine].set_linewidth(0.5)
        
    plt.tight_layout(rect=[0, 0, 1, 0.93])

    pdf_file = f"{figures_path}/{output_filename_base}.pdf"
    png_file = f"{figures_path}/{output_filename_base}.png"
    plt.savefig(pdf_file, bbox_inches='tight')
    plt.savefig(png_file, dpi=png_dpi, bbox_inches='tight')
    plt.close(fig)
    print(f"Exported {output_filename_base} (PDF and PNG)")

# --- Data and Calls for Each Plot ---

import os
figures_path = "/home/lr/Documents/HUNTER_SPRING/DEB_NONLINEAR/FINAL PROJECT/FIGURES"
if not os.path.exists(figures_path):
    os.makedirs(figures_path)

# 1. Plot for L_baa_aaa_spread
data_baa = {
    'varname': ["L_baa_aaa_spread"]*4,
    'model_type': ["QReg", "QReg", "QReg", "OLS"],
    'x_plot_val': [1, 2, 3, 2],
    'actual_quantile': [0.25, 0.50, 0.75, 0.50],
    'coef': [.2176301, .1949009, .2950031, .2677381],
    'se': [.0707064, .0765379, .0631350, .0500451]
}
create_coefficient_plot(data_dict=data_baa, 
                        var_name="L_baa_aaa_spread", 
                        y_axis_label_text="Coefficient Estimate", 
                        plot_title="Impact of Lagged Baa-Aaa Spread", 
                        plot_subtitle="QR (Shaded 95% CI) vs. OLS",
                        output_filename_base="py_plot_L_baa_aaa_spread",
                        figures_path=figures_path)

# 2. Plot for L_implied_vol
data_imp = {
    'varname': ["L_implied_vol"]*4,
    'model_type': ["QReg", "QReg", "QReg", "OLS"],
    'x_plot_val': [1, 2, 3, 2],
    'actual_quantile': [0.25, 0.50, 0.75, 0.50],
    'coef': [.0195332, .0172033, .0187183, .0190995],
    'se': [.0006594, .0009281, .0004731, .0004262]
}
create_coefficient_plot(data_dict=data_imp, 
                        var_name="L_implied_vol", 
                        y_axis_label_text="Coefficient Estimate", 
                        plot_title="Impact of Lagged Implied Volatility", 
                        plot_subtitle="QR (Shaded 95% CI) vs. OLS",
                        output_filename_base="py_plot_L_implied_vol",
                        figures_path=figures_path)

# 3. Plot for L_neg_log_ret
data_neg = {
    'varname': ["L_neg_log_ret"]*4,
    'model_type': ["QReg", "QReg", "QReg", "OLS"],
    'x_plot_val': [1, 2, 3, 2],
    'actual_quantile': [0.25, 0.50, 0.75, 0.50],
    'coef': [-3.685050, -2.922411, -1.460127, -2.568606],
    'se': [.7479351, .6534365, .6397796, .5771519]
}
create_coefficient_plot(data_dict=data_neg, 
                        var_name="L_neg_log_ret", 
                        y_axis_label_text="Coefficient Estimate", 
                        plot_title="Impact of Lagged Negative Log Returns (Leverage)", 
                        plot_subtitle="QR (Shaded 95% CI) vs. OLS",
                        output_filename_base="py_plot_L_neg_log_ret",
                        figures_path=figures_path)

print(f"All Python plots generated and saved in '{figures_path}' directory.")