# Remoteforests Disturbance

This repository contains scripts for disturbance history reconstructions.

## OLD

Disturbance history reconstruction according to [Schurman et al (2018)](#R).

## NEW

High-quality increment core samples (properly cross-dated, undamaged, and unrotten) obtained from live and recently dead (in the case of recently disturbed plots) trees with DBH \>= 10 cm were analysed to detect two types of tree canopy accession events: (1) release – abrupt, sustained increase in tree growth, indicating mortality of a former canopy tree, and (2) open canopy recruitment – rapid juvenile growth rates indicating recruitment in a former canopy gap ([Lorimer & Frelich, 1989](#R)).

Release events were identified using the absolute increase method ([Fraver & White, 2005](#R)) as pulses where the difference between average growth rates of adjacent 10-year running intervals (absolute increase) was greater than or equal to 1.25 standard deviations of all absolute increase values calculated for a given species group (*Abies*, *Acer*, *Fagus*, *Picea*, and *Others*). Releases where increased growth was not sustained for at least 7 years were excluded from further analysis as they were more likely to indicate a short-term improvement in growth conditions rather than a disturbance event ([Fraver et al., 2009](#R)). To reduce overestimation of disturbance severity caused by lateral releases of mature trees already present in the canopy ([Lorimer & Frelich, 1989](#R)), an optimal cutpoint (DBH = 25.1 cm) separating subcanopy and canopy trees was estimated based on the DBH distribution of suppressed and released trees, minimising the absolute difference of sensitivity and specificity (sensitivity = 0.92, specificity = 0.92, AUC = 0.98). Release events detected when the tree DBH was above or equal to this threshold were excluded from further analysis.

For the detection of open canopy recruitment, early growth rates of released and suppressed trees were calculated as 10-year averages from age 5 to 14 years ([Lorimer & Frelich, 1989](#R); [Splechtna et al., 2005](#R)) and used to estimate optimal cutpoints (OC) separating trees originating in the open canopy from those found under closed canopy conditions, minimising the absolute difference of sensitivity and specificity: *Abies* (OC = 1.509 mm, sensitivity = 0.67, specificity = 0.66, AUC = 0.71), *Acer* (OC = 2.244 mm, sensitivity = 0.72, specificity = 0.71, AUC = 0.79), *Fagus* (OC = 1.097 mm, sensitivity = 0.62, specificity = 0.62, AUC = 0.67), *Picea* (OC = 1.748 mm, sensitivity = 0.60, specificity = 0.60, AUC = 0.64), and *Others* (OC = 1.855 mm, sensitivity = 0.73, specificity = 0.75, AUC = 0.81). Trees with an early growth rate greater than or equal to the established threshold were considered recruited under open canopy conditions.

Because shade-tolerant tree species may need more than one disturbance to reach the canopy ([Lorimer & Frelich, 1989](#R)), multiple canopy accession events were allowed for individual trees. Trees exhibiting no signs of open canopy recruitment or release event were considered to have originated under open canopy conditions for the purposes of further analysis.

The percentage of disturbed canopy area on a plot was calculated for each year as a sum of the current crown areas of reacting trees (showing release or open canopy recruitment) divided by the total crown area of all the sampled trees (including trees with low-quality increment core samples to avoid overestimation of disturbance severity – see [Frelich, 2002](#R)). Current crown areas were predicted based on current DBH of trees using two linear mixed-effects models for coniferous (R2 (cond.) = 0.714, R2 (marg.) = 0.519, RMSE = 0.887 m) and broadleaved (R2 (cond.) = 0.692, R2 (marg.) = 0.545, RMSE = 1.642 m) species, which were calibrated on the sample of trees with measured crown dimensions and included random intercepts accounting for the sampling design levels (stand, cluster, plot).

To correct for differences in the intensity of increment core sampling, only currently released trees within a radius of 17.84 m from the plot center and replacements for missing or rotten trees collected outside this radius were used for the calculations and plots with fewer than 8 high-quality increment core samples were excluded from the analysis. Additionally, each plot was resampled by randomly taking 1,000 subsamples of size m = 8 (the maximum common number of sampled trees per plot). The calculation of disturbed canopy area percentage was performed for each subsample separately and then averaged on an annual basis to produce the final plot chronology.

To improve the temporal accuracy of the disturbance history reconstruction, each annually binned chronology of disturbed canopy area percentage was smoothed using kernel density estimation ([Trotsiuk et al., 2018](#R)) and individual plot-level disturbance events were detected as peaks with severity of more than 10% of disturbed canopy area.

[DIST_PARAMETER, DIST_TREE, DIST_PLOT, DIST_CHRONO, DIST_EVENT]

### References {#R}

Fraver, S., & White, A. S. (2005). Identifying growth releases in dendrochronological studies of forest disturbance. *Canadian Journal of Forest Research, 35*(7), 1648-1656. <https://doi.org/10.1139/x05-092>

Fraver, S., White, A. S., & Seymour, R. S. (2009). Natural disturbance in an old‐growth landscape of northern Maine, USA. *Journal of ecology, 97*(2), 289-298. <https://doi.org/10.1111/j.1365-2745.2008.01474.x>

Frelich, L. E. (2002). *Forest dynamics and disturbance regimes: studies from temperate evergreen-deciduous forests*. Cambridge University Press.

Lorimer, C. G., & Frelich, L. E. (1989). A methodology for estimating canopy disturbance frequency and intensity in dense temperate forests. *Canadian Journal of Forest Research, 19*(5), 651-663. <https://doi.org/10.1139/x89-102>

Schurman, J. S., Trotsiuk, V., Bače, R., Čada, V., Fraver, S., Janda, P., ... & Svoboda, M. (2018). Large‐scale disturbance legacies and the climate sensitivity of primary Picea abies forests. *Global change biology, 24*(5), 2169-2181. <https://doi.org/10.1111/gcb.14041>

Splechtna, B. E., Gratzer, G., & Black, B. A. (2005). Disturbance history of a European old-growth mixed-species forest – A spatial dendro-ecological analysis. *Journal of Vegetation Science, 16*(5), 511–522. <https://doi.org/10.1111/j.1654-1103.2005.tb02391.x>

Trotsiuk, V., Pederson, N., Druckenbrod, D. L., Orwig, D. A., Bishop, D. A., Barker-Plotkin, A., ... & Martin-Benito, D. (2018). Testing the efficacy of tree-ring methods for detecting past disturbances. *Forest Ecology and Management, 425*, 59-67. <https://doi.org/10.1016/j.foreco.2018.05.045>
