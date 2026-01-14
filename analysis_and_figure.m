%==========================================================================
% Quantitative survey analysis and visualization
%
% Article:
%   "What Is a Generative Model? Definitions, Disagreements, and Evaluation
%    in Human Neuroimaging"
%
% Authors:
%   Greaves, Novelli, Breakspear, and Razi
%
% This script reproduces all quantitative summaries and the figure reported
% in the article, using a de-identified survey dataset containing only
% revised codes and thematic variables.
%
% Full details of survey design, questions, recruitment, and qualitative
% analysis procedures are provided in the bioRxiv preprint (and its 
% accompanying supporting infromation).
%
% Data:
%   ./data/OHBM_survey_results_public.csv
%
% Notes:
% - The dataset contains no free-text responses or direct identifiers.
% - Initial fine-grained codes were not shared due to identifiability risks
%   in a small research community; revised codes and themes are public.
% - Minor encoding artifacts from CSV export (e.g., 'â') are corrected
%   locally where needed.
%
%==========================================================================

% Import data
survey_path = './data/OHBM_survey_results_public.csv';
T           = readtable(survey_path, 'VariableNamingRule', 'preserve');

% ========================================================================
% Demographics
% ========================================================================

% Career stage (Q11)
career  = categorical(T.Q11);
cats    = categories(career);
pct     = countcats(career) / sum(countcats(career)) * 100;
q       = table(cats, pct, 'VariableNames', {'career', 'percent'});
disp('Career Stage:');
disp(q);

% Gender (Q13)
gender  = categorical(T.Q13);
cats    = categories(gender);
pct     = countcats(gender) / sum(countcats(gender)) * 100;
q       = table(cats, pct, 'VariableNames', {'gender', 'percent'});
disp('Gender:');
disp(q);

% Age (Q12)
age     = categorical(T.Q12);
cats    = categories(age);

% Fix encoding artifact for age ranges (en dash rendered as 'â')
cats    = strrep(cats, 'â', ' –');
age     = renamecats(age, categories(age), cats);

pct     = countcats(age) / sum(countcats(age)) * 100;
q       = table(cats, pct, 'VariableNames', {'age', 'percent'});
disp('Age:');
disp(q);

% Country (Q14)
country     = categorical(T.Q14);
cats        = categories(country);
pct         = countcats(country) / sum(countcats(country)) * 100;
country_T   = table(cats, pct, 'VariableNames', {'country', 'percent'});
sortrows(country_T, 'percent', 'descend');

% Research area (Q10)
research    = categorical(T.Q10);
cats        = categories(research);
pct         = countcats(research) / sum(countcats(research)) * 100;
q           = table(cats, pct, 'VariableNames', {'research', 'percent'});
disp('Country:');
disp(q);

% ========================================================================
% Multi-select item: applications of generative models (Q7)
% ========================================================================

% Raw responses (semicolon-delimited selections)
raw = string(T.Q7);
raw = strtrim(raw);

% Treat empty strings as missing
raw(raw == "")  = missing;
raw             = raw(~ismissing(raw));
n_resp          = numel(raw);

% Canonical response options (matched by substring)
opts = {
    "Mechanistic/biophysical modeling"
    "Whole-brain dynamical modeling"
    "Synthetic data/augmentation"
    "Normative modeling/deviation maps"
    "Encoding/decoding models"
    "Clinical prediction/stratification"
    "Simulation-based inference / likelihood-free inference"
    "Other"
};

% Selection matrix: rows = respondents, columns = options
S = false(n_resp, numel(opts));
for j = 1:numel(opts)
    S(:,j) = contains(raw, opts{j}, 'IgnoreCase', true);
end

% Count and percentage of respondents selecting each option
counts      = sum(S, 1);
pct         = (counts ./ n_resp) * 100;

apps_table  = table(opts(:), counts(:), pct(:), ...
    'VariableNames', {'application', 'count', 'percent'});
apps_table  = sortrows(apps_table, 'percent', 'descend');

disp('Applications:');
disp(apps_table);
fprintf('\nRespondents answering this item: %d\n', n_resp);
fprintf('Mean selections per respondent: %.2f\n', mean(sum(S,2)));
fprintf('Min/Max selections per respondent: %d / %d\n\n', ...
    min(sum(S,2)), max(sum(S,2)));

% ========================================================================
% Conceptual boundary questions
% ========================================================================

% Explicit likelihood required? (Q3)
likelihood  = categorical(T.Q3);
cats        = categories(likelihood);
pct         = countcats(likelihood) / sum(countcats(likelihood)) * 100;
q           = table(cats, pct, 'VariableNames', {'likelihood', 'percent'});
disp('Explicit likelihood required?');
disp(q);


% Can a model be generative without simulating raw data? (Q4)
can_sim = categorical(T.Q4);
cats    = categories(can_sim);
pct     = countcats(can_sim) / sum(countcats(can_sim)) * 100;
q       = table(cats, pct, 'VariableNames', {'can_sim', 'percent'});
disp('Can a model be generative without simulating raw data?');
disp(q);

% ========================================================================
% Figure parameters
% ========================================================================

axis_font_size  = 16;
annot_font_size = 18;

% ColorBrewer qualitative palette (Set3)
cmap_meth = [
    0.7451, 0.7294, 0.8549;    % Lavender
    0.5020, 0.6941, 0.8275;    % Blue
    0.8510, 0.8510, 0.8510;    % Light gray
    1.0000, 0.9294, 0.4353     % Soft gold
];

% ========================================================================
% Fig. 1a — Definitions of generative models (Q2)
% ========================================================================

gen_model = categorical(T.Q2);
cats_gen  = categories(gen_model);
pct_gen   = countcats(gen_model) / sum(countcats(gen_model)) * 100;

short_labels = {
    'Latent-variable (hidden-cause) models'
    'Mechanistic forward models'
    'Statistical models of data distributions'
    'Autoregressive time-series models'
    'Synthetic-data-generating models'
    'Other'
};

fig = figure('Color','w','Units','normalized','Position',[0 1 1 3/5]);
ax_a = subplot(1,3,1);

b = barh(pct_gen(1:end-1));   % exclude "Other"
b.FaceColor = cmap_meth(2,:);
b.EdgeColor = 'none';

set(ax_a, ...
    'YTick', 1:numel(short_labels)-1, ...
    'YTickLabel', short_labels(1:end-1), ...
    'TickLength', [0 0], ...
    'FontName', 'Helvetica', ...
    'FontSize', axis_font_size);
xlabel('Percentage of responses');
set(gca,'YDir','reverse');
box off;

% ========================================================================
% Fig. 1b — Disagreement about what counts as generative (Q5)
% ========================================================================

dt_frame = {
'Model class (collapsed label)',           'Yes', 'No'
'Autoencoders / variational autoencoders', '✓',   ''
'Autoregressive models',                   '✓',   '✓'
'Bayesian / probabilistic models',         '✓',   '✓'
'Classical statistical tests',             '',    '✓'
'Correlation-based connectivity',          '',    '✓'
'Diffusion models',                        '✓',   ''
'Dynamic causal models',                   '✓',   '✓'
'Generative adversarial networks',         '✓',   ''
'General linear model',                    '✓',   '✓'
'Large language and retrieval models',     '✓',   ''
'Neural network models',                   '✓',   '✓'
'Support vector machines',                 '',    '✓'
};

hdr     = dt_frame(1,:);
rows    = dt_frame(2:end,1);
gen     = dt_frame(2:end,2);
ngen    = dt_frame(2:end,3);

X       = zeros(numel(rows),2);
X(:,1)  = strcmp(gen,'✓');
X(:,2)  = strcmp(ngen,'✓');

ax_b = subplot(1,3,2);
imagesc(X); axis ij tight;
colormap([cmap_meth(3,:); cmap_meth(4,:)]);
set(gca, ...
    'XTick', 1:2, 'XTickLabel', hdr(2:3), ...
    'YTick', 1:numel(rows), 'YTickLabel', rows, ...
    'TickLength',[0 0], ...
    'FontName','Helvetica', 'FontSize', axis_font_size);

% Draw table grid
hold on;
for r = 0.5:1:(size(X,1)+0.5)
    plot([0.5 2.5],[r r],'k-','LineWidth',0.5);
end
for c = 0.5:1:(size(X,2)+0.5)
    plot([c c],[0.5 size(X,1)+0.5],'k-','LineWidth',0.5);
end

% Overlay checkmarks
for i = 1:size(X,1)
    for j = 1:size(X,2)
        if X(i,j)
            text(j,i,'✓','HorizontalAlignment','center', ...
                'VerticalAlignment','middle','FontSize',14);
        end
    end
end
xlabel('Generative model');
hold off;

% ========================================================================
% Fig. 1c — Evidence for a "good" model (Q8)
% ========================================================================

rankCats = {
    categorical(T.Q8a)
    categorical(T.Q8b)
    categorical(T.Q8c)
    categorical(T.Q8d)
    categorical(T.Q8e)
    categorical(T.Q8f)
    categorical(T.Q8g)
    categorical(T.Q8h)
};

labels = {
    'Out-of-sample predictive accuracy'
    'Model evidence'
    'Posterior predictive checks'
    'Parameter recovery and robustness'
    'Synthetic data realism'
    'Biological interpretability of parameters'
    'Computational efficiency'
    'Reproducibility across datasets'
};

K = numel(rankCats);
N = numel(rankCats{1});

R = nan(N, K);
for j = 1:K
    R(:,j) = double(rankCats{j});
end

% Aggregate inverse-rank score (higher = more preferred)
invScore = sum(1 ./ R, 1, 'omitnan');

[invScore_sorted, idx] = sort(invScore, 'descend');

ax_c = subplot(1,3,3);
b = barh(invScore_sorted);
b.FaceColor = cmap_meth(1,:);
b.EdgeColor = 'none';

set(gca, ...
    'YTick', 1:K, ...
    'YTickLabel', labels(idx), ...
    'TickLength', [0 0], ...
    'FontName', 'Helvetica', ...
    'FontSize', axis_font_size);
xlabel('Sum of inverse rank');
set(gca,'YDir','reverse');

% ========================================================================
% Final layout adjustments and panel labels
% ========================================================================

set(ax_a, 'Position', [0.20 0.11 0.12 0.815]);
set(ax_b, 'Position', [0.53 0.11 0.12 0.815]);
set(ax_c, 'Position', [0.85 0.11 0.12 0.815]);

text(ax_a, -0.18, 1.02, 'a', 'Units','normalized', ...
    'FontSize',annot_font_size,'FontWeight','bold');
text(ax_b, -0.18, 1.02, 'b', 'Units','normalized', ...
    'FontSize',annot_font_size,'FontWeight','bold');
text(ax_c, -0.18, 1.02, 'c', 'Units','normalized', ...
    'FontSize',annot_font_size,'FontWeight','bold');

%--------------------------------------------------------------------------
% Script author:
%   Matthew D. Greaves
%   Department of Psychiatry
%   The University of Melbourne, Australia
%
% Date:
%   December 2025
%--------------------------------------------------------------------------
