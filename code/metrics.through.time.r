## code for relating various metrics of the root clade to time and making plots
require(abind)
require(apTreeshape)
require(ape)

#Energy gradient sims
# currently has 100 sims
trop.sims = c(4065:4074, 4185:4274)
temp.sims = c(4075:4084, 4275:4364)

#No energy gradient sims
# currently has 100 sims
Ttrop.sims = 3465:3564
Ttemp.sims = 3565:3664

sim.matrix = read.csv("SENC_Master_Simulation_Matrix.csv",header=T);

# Function for abinding simulation output (the "stats" files where rows are points in time)
# across all of the replicates with identical parameters
metric.abind.new = function(sims, min.div.regions = 4, min.richness = 30) {
  num.cols = 41
  metrics = matrix(NA, nrow = 100, ncol = num.cols)
  for (i in sims) {
    statsfile = list.files(path = "analysis_output", pattern = paste("Stats_sim", i, "_rootclade", sep = ""))
    temp = read.csv(paste("analysis_output/", statsfile, sep = ""), header = T)
    temp$r.lat.rich = -temp$r.env.rich
    temp$scaled.MRD.range = temp$MRD.range/temp$max.RD
    temp$scaled.MRD.rich.slope = temp$MRD.rich.slope/temp$max.RD

    # There is no output for timesteps in which no correlations could be calculated
    # so we add the relevant number of rows of data with NA's in that case
    if (nrow(temp) < 100) {
      temp.top = data.frame(matrix(NA, nrow = 100 - nrow(temp), ncol = num.cols))
      names(temp.top) = names(temp)
      temp = rbind(temp.top, temp)
    }
    # Only include metrics in analysis if simulation meets minimum region and richness criteria
    if (min(temp$n.div.regions, na.rm = T) < min.div.regions) {
      temp[which(temp$n.div.regions < min.div.regions),] = NA
    }
    if (min(temp$global.richness, na.rm = T) < min.richness) {
      temp[which(temp$global.richness < min.richness),] = NA
    }
    metrics = abind(metrics, temp, along = 3)
  }
  return(metrics[,,-1]) #don't include the first slice of NAs
}

min.num.regions = 5
min.num.div.regions = 5
min.global.richness = 30

temp.metrics = metric.abind.new(temp.sims, scenario = "K", min.div.regions = min.num.div.regions, min.richness = min.global.richness)
trop.metrics = metric.abind.new(trop.sims, scenario = "K", min.div.regions = min.num.div.regions, min.richness = min.global.richness)
Ttemp.metrics = metric.abind.new(Ttemp.sims, scenario = "T", min.div.regions = min.num.div.regions, min.richness = min.global.richness)
Ttrop.metrics = metric.abind.new(Ttrop.sims, scenario = "T", min.div.regions = min.num.div.regions, min.richness = min.global.richness)

#Function for calculating mean or SD for simulations with a minimum number of non-NA values at a given time step
calc.meanSD = function(x, stat = 'mean', min.num.nonNA = 10) {
  if (stat == 'mean') {
    if(sum(!is.na(x)) >= min.num.nonNA) {
      mean(x, na.rm = T)
    } else { NA }
  } else if (stat == 'sd') {
    if(sum(!is.na(x)) >= min.num.nonNA) {
      var(x, na.rm = T)^0.5
    } else { NA }
  }
}

min.num.datapts = 10

temp.metrics.mean = data.frame(apply(temp.metrics, 1:2, function(x) calc.meanSD(x, stat = 'mean', min.num.nonNA = min.num.datapts)))
temp.metrics.sd = data.frame(apply(temp.metrics, 1:2, function(x) calc.meanSD(x, stat = 'sd', min.num.nonNA = min.num.datapts)))

trop.metrics.mean = data.frame(apply(trop.metrics, 1:2, function(x) calc.meanSD(x, stat = 'mean', min.num.nonNA = min.num.datapts)))
trop.metrics.sd = data.frame(apply(trop.metrics, 1:2, function(x) calc.meanSD(x, stat = 'sd', min.num.nonNA = min.num.datapts)))

Ttemp.metrics.mean = data.frame(apply(Ttemp.metrics, 1:2, function(x) calc.meanSD(x, stat = 'mean', min.num.nonNA = min.num.datapts)))
Ttemp.metrics.sd = data.frame(apply(Ttemp.metrics, 1:2, function(x) calc.meanSD(x, stat = 'sd', min.num.nonNA = min.num.datapts)))

Ttrop.metrics.mean = data.frame(apply(Ttrop.metrics, 1:2, function(x) calc.meanSD(x, stat = 'mean', min.num.nonNA = min.num.datapts)))
Ttrop.metrics.sd = data.frame(apply(Ttrop.metrics, 1:2, function(x) calc.meanSD(x, stat = 'sd', min.num.nonNA = min.num.datapts)))

metric.names = c('global.richness',
                 'r.lat.rich', 
                 'gamma.stat',
                 'r.env.PSV', 
                 'r.env.MRD', 
                 'r.MRD.rich',
                 'r.PSV.rich',
                 'MRD.rich.slope',
                 'MRD.env.slope',
                 'PSV.rich.slope',
                 'PSV.env.slope',
                 'MRD.range',
                 'PSV.range',
                 'MRD.mean',
                 'PSV.mean',
                 'tree.beta',
                 'scaled.MRD.range',
                 'scaled.MRD.rich.slope')

metric.labels = c('Global richness', 
                  expression(italic(r)[latitude-richness]), 
                  expression(gamma), 
                  expression(italic(r)[env-PSV]),
                  expression(italic(r)[env-MRD]), 
                  expression(italic(r)[MRD-richness]),
                  expression(italic(r)[PSV-richness]),
                  'MRD-Richness slope',
                  'MRD-Environment slope',
                  'PSV-Richness slope',
                  'PSV-Environment slope',
                  'MRD range',
                  'PSV range',
                  'Mean MRD',
                  'Mean PSV',
                  expression(beta),
                  'scaled MRD range',
                  'MRD-richness slope')


# Plotting metrics over the course of the simulation: EXPLORATORY PLOTS
par(mfrow = c(2, 2), mar = c(5, 6, 1, 1), oma = c(5, 0, 0, 0), cex.lab = 2, las = 1, cex.axis = 1.3, mgp = c(4,1,0))

# Specify variables to plot here, and width of error bars
names4plotting = c('global.richness','r.lat.rich', 'scaled.MRD.rich.slope', 'tree.beta')
#names4plotting = c('r.env.PSV', 'r.env.MRD', 'r.MRD.rich','r.PSV.rich')
#names4plotting = c('MRD.rich.slope', 'scaled.MRD.rich.slope','scaled.MRD.range','tree.beta')
error = 2 # error bars in SD units (+/-)
for (j in 1:4) {
  curr.metric = names4plotting[j]
  plot(trop.metrics.mean$time/1000, trop.metrics.mean[, curr.metric], xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
       ylim = range(c(trop.metrics[, curr.metric, ], temp.metrics[, curr.metric, ], 
                      Ttrop.metrics[, curr.metric, ], Ttemp.metrics[, curr.metric, ]), na.rm= T), type = "n",
       ylab = metric.labels[metric.names == curr.metric], xlab = "")
  polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
          c(trop.metrics.mean[, curr.metric] - error*trop.metrics.sd[, curr.metric], 
            rev(trop.metrics.mean[, curr.metric] + error*trop.metrics.sd[, curr.metric])), 
          col = rgb(.8, 0, 0, .3), border = NA)
  polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
          c(temp.metrics.mean[, curr.metric] - error*temp.metrics.sd[, curr.metric], 
            rev(temp.metrics.mean[, curr.metric] + error*temp.metrics.sd[, curr.metric])), 
          col = rgb(0, 0, .8, .3), border = NA)
  points(trop.metrics.mean$time/1000, trop.metrics.mean[, curr.metric], type = 'l', col = 'red', lwd = 3)
  points(temp.metrics.mean$time/1000, temp.metrics.mean[, curr.metric], type = 'l', col = 'blue', lwd = 3)
  
  par(new = T)
  
  plot(Ttemp.metrics.mean$time - min(Ttemp.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, curr.metric], 
       xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - min(Ttemp.metrics.mean$time, na.rm = T)), 
       ylim = range(c(trop.metrics[, curr.metric, ], temp.metrics[, curr.metric, ], 
                      Ttrop.metrics[, curr.metric, ], Ttemp.metrics[, curr.metric, ]), na.rm= T), type = "n",
       ylab = "", xlab = "", yaxt = "n", xaxt = "n")
  polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
          c(Ttrop.metrics.mean[, curr.metric] - error*Ttrop.metrics.sd[, curr.metric], 
            rev(Ttrop.metrics.mean[, curr.metric] + error*Ttrop.metrics.sd[, curr.metric])), 
          col = rgb(.8, 0, 0, .3), border = NA)
  polygon(c(Ttemp.metrics.mean$time - min(Ttemp.metrics.mean$time, na.rm = T), rev(Ttemp.metrics.mean$time - min(Ttemp.metrics.mean$time, na.rm = T))), 
          c(Ttemp.metrics.mean[, curr.metric] - error*Ttemp.metrics.sd[, curr.metric], 
            rev(Ttemp.metrics.mean[, curr.metric] + error*Ttemp.metrics.sd[, curr.metric])), 
          col = rgb(0, 0, .8, .3), border = NA)
  points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, curr.metric], type = 'l', col = 'red', lwd = 3, lty = 'dashed')
  points(Ttemp.metrics.mean$time - min(Ttemp.metrics.mean$time, na.rm = T), Ttemp.metrics.mean[, curr.metric], type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
  alt.x.vals = c(120, 140, 160, 180)
  mtext(alt.x.vals, 1, at = alt.x.vals - min(Ttemp.metrics.mean$time, na.rm=T), line = 2.5, col = 'gray50')
  
  if(curr.metric == 'gamma.stat') { abline(h = 0, lty = 'dashed')}
} 
mtext("Time (x1000, Energy Gradient)", 1, outer=T, cex = 1.75, line = 1.5) 
mtext("Time (No Energy Gradient)", 1, outer = T, cex = 1.75, line = 3.5, col = 'gray50')
dev.off()



#-------------------------------------------------------------------------------------------------------
# FINAL FIGURES

error = 2 # error bars in SD units (+/-)

# Figure 2
# Plotting metrics over the course of the simulation: global richness, the latitude-richness correlation 
# Means +/- 2 SD are shown.
pdf(paste('rich_latrich_thru_time_',Sys.Date(), '.pdf', sep = ""), height = 5, width = 10)
par(mfrow = c(1, 2), mar = c(4, 6, 1, 1), oma = c(2, 0, 2, 0), cex.lab = 1.7, las = 1, cex.axis = 1.3, mgp = c(4,1,0))

x.offset = min(Ttemp.metrics.mean$time, na.rm = T)

## (a) Global richness thru time
# zero-sum results
plot(trop.metrics.mean$time/1000, log10(trop.metrics.mean[, 'global.richness']), xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
     ylim = c(1.5, log10(max(Ttrop.metrics[, 'global.richness', ], Ttemp.metrics[, 'global.richness', ], na.rm= T))), type = "n",
     ylab = expression(paste(plain(log[10]), " Global richness")), xlab = "")
polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
        log10(c(trop.metrics.mean[, 'global.richness'] - error*trop.metrics.sd[, 'global.richness'], 
                rev(trop.metrics.mean[, 'global.richness'] + error*trop.metrics.sd[, 'global.richness']))), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
        log10(c(temp.metrics.mean[, 'global.richness'] - error*temp.metrics.sd[, 'global.richness'], 
                rev(temp.metrics.mean[, 'global.richness'] + error*temp.metrics.sd[, 'global.richness']))), 
        col = rgb(0, 0, .8, .3), border = NA)
points(trop.metrics.mean$time/1000, log10(trop.metrics.mean[, 'global.richness']), type = 'l', col = 'red', lwd = 3)
points(temp.metrics.mean$time/1000, log10(temp.metrics.mean[, 'global.richness']), type = 'l', col = 'blue', lwd = 3)

par(new=T)

# non-zero sum results
plot(Ttemp.metrics.mean$time - x.offset, log10(Ttrop.metrics.mean[, 'global.richness']), 
     xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - x.offset), 
     ylim = c(1.5, log10(max(c(Ttrop.metrics[, 'global.richness', ], Ttemp.metrics[, 'global.richness', ]), na.rm= T))), type = "n",
     ylab = "", xlab = "", yaxt = "n", xaxt = "n")
polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
        log10(c(Ttrop.metrics.mean[, 'global.richness'] - error*Ttrop.metrics.sd[, 'global.richness'], 
                rev(Ttrop.metrics.mean[, 'global.richness'] + error*Ttrop.metrics.sd[, 'global.richness']))), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(Ttemp.metrics.mean$time - x.offset, rev(Ttemp.metrics.mean$time - x.offset)), 
        log10(c(Ttemp.metrics.mean[, 'global.richness'] - error*Ttemp.metrics.sd[, 'global.richness'], 
                rev(Ttemp.metrics.mean[, 'global.richness'] + error*Ttemp.metrics.sd[, 'global.richness']))), 
        col = rgb(0, 0, .8, .3), border = NA)
points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), log10(Ttrop.metrics.mean[, 'global.richness']), type = 'l', col = 'red', lwd = 3, lty = 'dashed')
points(Ttemp.metrics.mean$time - x.offset, log10(Ttemp.metrics.mean[, 'global.richness']), type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
alt.x.vals = c(120, 140, 160, 180)
#mtext(alt.x.vals, 1, at = alt.x.vals - x.offset, line = 2.5, col = 'gray50')
mtext("(a)", 3, adj=0, outer=T, cex = 2)

legend(146 - x.offset, 2.43, legend = c('zero sum', 'no zero sum', 'tropical origin', 'temperate origin'), 
       lty = c('solid', 'dashed', 'dashed', 'dashed'), text.col = 'white', cex = 1.2,
       col = c('blue', 'blue', 'red', 'blue'), bty = "n", lwd = 3, y.intersp = 1.1)
legend('bottomright', c('zero sum', 'no zero sum', 'tropical origin', 'temperate origin'), 
       lty = c('solid', 'dashed', 'solid', 'solid'), y.intersp = 1.1, bty = "n",
       lwd = 3, col = c('red', 'red', 'red', 'blue'), cex = 1.2)


## (b) latitude-richness correlation through time
# zero-sum results
plot(trop.metrics.mean$time/1000, trop.metrics.mean[, 'r.lat.rich'], xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
     ylim = range(c(trop.metrics[, 'r.lat.rich', ], temp.metrics[, 'r.lat.rich', ], 
                    Ttrop.metrics[, 'r.lat.rich', ], Ttemp.metrics[, 'r.lat.rich', ]), na.rm= T), type = "n",
     ylab = metric.labels[metric.names == 'r.lat.rich'], xlab = "")
polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
        c(trop.metrics.mean[, 'r.lat.rich'] - error*trop.metrics.sd[, 'r.lat.rich'], 
          rev(trop.metrics.mean[, 'r.lat.rich'] + error*trop.metrics.sd[, 'r.lat.rich'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
        c(temp.metrics.mean[, 'r.lat.rich'] - error*temp.metrics.sd[, 'r.lat.rich'], 
          rev(temp.metrics.mean[, 'r.lat.rich'] + error*temp.metrics.sd[, 'r.lat.rich'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(trop.metrics.mean$time/1000, trop.metrics.mean[, 'r.lat.rich'], type = 'l', col = 'red', lwd = 3)
points(temp.metrics.mean$time/1000, temp.metrics.mean[, 'r.lat.rich'], type = 'l', col = 'blue', lwd = 3)

par(new = T)

# non-zero-sum results
plot(Ttemp.metrics.mean$time - x.offset, Ttrop.metrics.mean[, 'r.lat.rich'], 
     xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - x.offset), 
     ylim = range(c(trop.metrics[, 'r.lat.rich', ], temp.metrics[, 'r.lat.rich', ], 
                    Ttrop.metrics[, 'r.lat.rich', ], Ttemp.metrics[, 'r.lat.rich', ]), na.rm= T), type = "n",
     ylab = "", xlab = "", yaxt = "n", xaxt = "n")
polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
        c(Ttrop.metrics.mean[, 'r.lat.rich'] - error*Ttrop.metrics.sd[, 'r.lat.rich'], 
          rev(Ttrop.metrics.mean[, 'r.lat.rich'] + error*Ttrop.metrics.sd[, 'r.lat.rich'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(Ttemp.metrics.mean$time - x.offset, rev(Ttemp.metrics.mean$time - x.offset)), 
        c(Ttemp.metrics.mean[, 'r.lat.rich'] - error*Ttemp.metrics.sd[, 'r.lat.rich'], 
          rev(Ttemp.metrics.mean[, 'r.lat.rich'] + error*Ttemp.metrics.sd[, 'r.lat.rich'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, 'r.lat.rich'], type = 'l', col = 'red', lwd = 3, lty = 'dashed')
points(Ttemp.metrics.mean$time - x.offset, Ttemp.metrics.mean[, 'r.lat.rich'], type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
alt.x.vals = c(120, 140, 160, 180)
#mtext(alt.x.vals, 1, at = alt.x.vals - min(Ttemp.metrics.mean$time, na.rm=T), line = 2.5, col = 'gray50')

mtext("Time", 1, outer=T, cex = 1.3, line = 0) 
#mtext("Time (no zero sum)", 1, outer = T, cex = 1.3, line = 1.25, col = 'gray50')
mtext("(b)", 3, adj=0.5, outer=T, cex = 2)
dev.off()



# Figure 4
# Plotting metrics over the course of the simulation: the scaled MRD-richness slope, and tree imbalance (beta),
# PSV-richness slope, and gamma. 
# Means +/- 2 SD are shown.

# First, calculate empirical values of beta and scaled MRD-richness slope for Sebastes
phy = read.tree('Sebastes_tree_Ingram2011PRSB.phy')
sebastes = read.csv('sebastes_data_for_allen.csv', header=T)
#Drop non-NorthEasternPacific species (with no latitude data)
nonNEPsp = as.character(sebastes[is.na(sebastes$min_latitude), 'X'])
NEPphy = drop.tip(phy,nonNEPsp)

# Beta
seb.beta = maxlik.betasplit(NEPphy)$max_lik

# Gamma
seb.gamma = gammaStat(NEPphy)

# MRD-richness
lat = 23:66 #latitudinal bins
richness = sapply(lat, function(x) nrow(subset(sebastes, min_latitude <= x & max_latitude >= x)))

phylo.bl1 <- compute.brlen(NEPphy, 1)
all.dist <- dist.nodes(phylo.bl1)
root.dist <- all.dist[length(NEPphy$tip.label)+1, 1:length(NEPphy$tip.label)]
tips.to.root <- data.frame(spp.name=NEPphy$tip.label,root.dist)

output = c()
for (i in lat) {
  species = subset(sebastes, min_latitude <= i & max_latitude >= i, select='X')
  
  #MRD
  MRD.ini <- merge(species, tips.to.root, by.x="X", by.y="spp.name",sort = FALSE)
  MRD <- mean(MRD.ini$root.dist)
  
  #PSV
  Vmatrix = vcv(NEPphy, corr=F)
  psvs = matrix(NA, ncol=2)
  
  index = row.names(Vmatrix) %in% species$X
  v.matrix = Vmatrix[index,index]
  n = nrow(v.matrix)
  psv = (n*sum(diag(v.matrix)) - sum(v.matrix))/(sum(diag(v.matrix))*(n-1))
  
  output = rbind(output, c(i, MRD, psv))
}
output2 = data.frame(cbind(output, richness))
names(output2) = c('lat','MRD','PSV','S')

seb.MRD.rich.slope = coefficients(lm(MRD ~ S, data = output2))[2]
seb.MRD.rich.slope.scaled = seb.MRD.rich.slope / max(root.dist)
seb.PSV.rich.slope = coefficients(lm(PSV ~ S, data = output2))[2]

# plot
pdf(paste('metrics_thru_time_', Sys.Date(), '.pdf', sep = ""), height = 8, width = 10)
par(mfrow = c(2, 2), mar = c(4, 6, 1, 2), oma = c(2, 0, 2, 0), cex.lab = 1.7, las = 1, cex.axis = 1.3, mgp = c(4,1,0))

x.offset = min(Ttemp.metrics.mean$time, na.rm = T)
error = 2 # +/- this many standard deviations for envelope
empirical.lty = '92'
empirical.lwd = 1.5

## (a) gamma
# zero sum results
plot(trop.metrics.mean$time/1000, trop.metrics.mean[, 'gamma.stat'], xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
     ylim = range(c(trop.metrics[, 'gamma.stat', ], temp.metrics[, 'gamma.stat', ], 
                    Ttrop.metrics[, 'gamma.stat', ], Ttemp.metrics[, 'gamma.stat', ]), na.rm= T), type = "n",
     ylab = metric.labels[metric.names == 'gamma.stat'], xlab = "", cex.lab = 2)
polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
        c(trop.metrics.mean[, 'gamma.stat'] - error*trop.metrics.sd[, 'gamma.stat'], 
          rev(trop.metrics.mean[, 'gamma.stat'] + error*trop.metrics.sd[, 'gamma.stat'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
        c(temp.metrics.mean[, 'gamma.stat'] - error*temp.metrics.sd[, 'gamma.stat'], 
          rev(temp.metrics.mean[, 'gamma.stat'] + error*temp.metrics.sd[, 'gamma.stat'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(trop.metrics.mean$time/1000, trop.metrics.mean[, 'gamma.stat'], type = 'l', col = 'red', lwd = 3)
points(temp.metrics.mean$time/1000, temp.metrics.mean[, 'gamma.stat'], type = 'l', col = 'blue', lwd = 3)

# vertical line at equilibrium time point
eq.time = 20 # in thousands of time steps
abline(v = eq.time)

par(new = T)

# non-zero-sum results
plot(Ttemp.metrics.mean$time - x.offset, Ttrop.metrics.mean[, 'gamma.stat'], 
     xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - x.offset), 
     ylim = range(c(trop.metrics[, 'gamma.stat', ], temp.metrics[, 'gamma.stat', ], 
                    Ttrop.metrics[, 'gamma.stat', ], Ttemp.metrics[, 'gamma.stat', ]), na.rm= T), type = "n",
     ylab = "", xlab = "", yaxt = "n", xaxt = "n")
polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
        c(Ttrop.metrics.mean[, 'gamma.stat'] - error*Ttrop.metrics.sd[, 'gamma.stat'], 
          rev(Ttrop.metrics.mean[, 'gamma.stat'] + error*Ttrop.metrics.sd[, 'gamma.stat'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(Ttemp.metrics.mean$time - x.offset, rev(Ttemp.metrics.mean$time - x.offset)), 
        c(Ttemp.metrics.mean[, 'gamma.stat'] - error*Ttemp.metrics.sd[, 'gamma.stat'], 
          rev(Ttemp.metrics.mean[, 'gamma.stat'] + error*Ttemp.metrics.sd[, 'gamma.stat'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, 'gamma.stat'], type = 'l', col = 'red', lwd = 3, lty = 'dashed')
points(Ttemp.metrics.mean$time - x.offset, Ttemp.metrics.mean[, 'gamma.stat'], type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
alt.x.vals = c(120, 140, 160, 180)
#mtext(alt.x.vals, 1, at = alt.x.vals - min(Ttemp.metrics.mean$time, na.rm=T), line = 2.5, col = 'gray50')
mtext("(a)", 2, at = 22, cex = 2, outer = F, las = 1, line = 3)

# empirical value
abline(h = seb.gamma, lty = empirical.lty, lwd = empirical.lwd) 

# legend
legend(154.5 - x.offset, -11, legend = c('zero sum', 'no zero sum', 'tropical origin', 'temperate origin', expression(italic(Sebastes))), 
       lty = c('solid', 'dashed', 'dashed', 'dashed', 'solid'), text.col = 'white', cex = 1.2,
       col = c('blue', 'blue', 'red', 'blue', 'white'), bty = "n", lwd = 3, seg.len = 2, y.intersp = 1)
legend('bottomright', c('zero sum', 'no zero sum', 'tropical origin', 'temperate origin', expression(italic(Sebastes))), 
       lty = c('solid', 'dashed', 'solid', 'solid', empirical.lty), y.intersp = 1, bty = "n",
       lwd = c(3, 3, 3, 3, empirical.lwd), col = c('red', 'red', 'red', 'blue', 'black'), cex = 1.2)


## (b) beta (tree imbalance)
# zero sum results
plot(trop.metrics.mean$time/1000, trop.metrics.mean[, 'tree.beta'], xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
         ylim = range(c(trop.metrics[, 'tree.beta', ], temp.metrics[, 'tree.beta', ], 
                        Ttrop.metrics[, 'tree.beta', ], Ttemp.metrics[, 'tree.beta', ]), na.rm= T), type = "n",
         ylab = metric.labels[metric.names == 'tree.beta'], xlab = "", cex.lab = 2)
polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
        c(trop.metrics.mean[, 'tree.beta'] - error*trop.metrics.sd[, 'tree.beta'], 
          rev(trop.metrics.mean[, 'tree.beta'] + error*trop.metrics.sd[, 'tree.beta'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
        c(temp.metrics.mean[, 'tree.beta'] - error*temp.metrics.sd[, 'tree.beta'], 
          rev(temp.metrics.mean[, 'tree.beta'] + error*temp.metrics.sd[, 'tree.beta'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(trop.metrics.mean$time/1000, trop.metrics.mean[, 'tree.beta'], type = 'l', col = 'red', lwd = 3)
points(temp.metrics.mean$time/1000, temp.metrics.mean[, 'tree.beta'], type = 'l', col = 'blue', lwd = 3)

# vertical line at equilibrium time point
abline(v = eq.time)

par(new = T)

# non-zero-sum results
plot(Ttemp.metrics.mean$time - x.offset, Ttrop.metrics.mean[, 'tree.beta'], 
     xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - x.offset), 
     ylim = range(c(trop.metrics[, 'tree.beta', ], temp.metrics[, 'tree.beta', ], 
                    Ttrop.metrics[, 'tree.beta', ], Ttemp.metrics[, 'tree.beta', ]), na.rm= T), type = "n",
     ylab = "", xlab = "", yaxt = "n", xaxt = "n")
polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
        c(Ttrop.metrics.mean[, 'tree.beta'] - error*Ttrop.metrics.sd[, 'tree.beta'], 
          rev(Ttrop.metrics.mean[, 'tree.beta'] + error*Ttrop.metrics.sd[, 'tree.beta'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(Ttemp.metrics.mean$time - x.offset, rev(Ttemp.metrics.mean$time - x.offset)), 
        c(Ttemp.metrics.mean[, 'tree.beta'] - error*Ttemp.metrics.sd[, 'tree.beta'], 
          rev(Ttemp.metrics.mean[, 'tree.beta'] + error*Ttemp.metrics.sd[, 'tree.beta'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, 'tree.beta'], type = 'l', col = 'red', lwd = 3, lty = 'dashed')
points(Ttemp.metrics.mean$time - x.offset, Ttemp.metrics.mean[, 'tree.beta'], type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
alt.x.vals = c(120, 140, 160, 180)
#mtext(alt.x.vals, 1, at = alt.x.vals - min(Ttemp.metrics.mean$time, na.rm=T), line = 2.5, col = 'gray50')
mtext("(b)", 2, at = 2.6, cex = 2, outer = F, las = 1, line = 3)

# empirical value
abline(h = seb.beta, lty = empirical.lty, lwd = empirical.lwd) 


## (c) PSV-richness slope
# zero sum results
plot(trop.metrics.mean$time/1000, trop.metrics.mean[, 'PSV.rich.slope'], xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
     ylim = c(-.008, 0.015), type = "n",
     ylab = metric.labels[metric.names == 'PSV.rich.slope'], xlab = "", yaxt = "n")
axis(2, labels = seq(-5, 15, by = 5), at = seq(-0.005, 0.015, by = .005))
polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
        c(trop.metrics.mean[, 'PSV.rich.slope'] - error*trop.metrics.sd[, 'PSV.rich.slope'], 
          rev(trop.metrics.mean[, 'PSV.rich.slope'] + error*trop.metrics.sd[, 'PSV.rich.slope'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
        c(temp.metrics.mean[, 'PSV.rich.slope'] - error*temp.metrics.sd[, 'PSV.rich.slope'], 
          rev(temp.metrics.mean[, 'PSV.rich.slope'] + error*temp.metrics.sd[, 'PSV.rich.slope'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(trop.metrics.mean$time/1000, trop.metrics.mean[, 'PSV.rich.slope'], type = 'l', col = 'red', lwd = 3)
points(temp.metrics.mean$time/1000, temp.metrics.mean[, 'PSV.rich.slope'], type = 'l', col = 'blue', lwd = 3)

# vertical line at equilibrium time point
abline(v = eq.time)

par(new = T)

# non-zero-sum results
plot(Ttemp.metrics.mean$time - x.offset, Ttrop.metrics.mean[, 'PSV.rich.slope'], 
     xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - x.offset), 
     ylim = c(-.008, 0.015), type = "n",
     ylab = "", xlab = "", yaxt = "n", xaxt = "n")
polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
        c(Ttrop.metrics.mean[, 'PSV.rich.slope'] - error*Ttrop.metrics.sd[, 'PSV.rich.slope'], 
          rev(Ttrop.metrics.mean[, 'PSV.rich.slope'] + error*Ttrop.metrics.sd[, 'PSV.rich.slope'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(Ttemp.metrics.mean$time - x.offset, rev(Ttemp.metrics.mean$time - x.offset)), 
        c(Ttemp.metrics.mean[, 'PSV.rich.slope'] - error*Ttemp.metrics.sd[, 'PSV.rich.slope'], 
          rev(Ttemp.metrics.mean[, 'PSV.rich.slope'] + error*Ttemp.metrics.sd[, 'PSV.rich.slope'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, 'PSV.rich.slope'], type = 'l', col = 'red', lwd = 3, lty = 'dashed')
points(Ttemp.metrics.mean$time - x.offset, Ttemp.metrics.mean[, 'PSV.rich.slope'], type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
alt.x.vals = c(120, 140, 160, 180)
#mtext(alt.x.vals, 1, at = alt.x.vals - min(Ttemp.metrics.mean$time, na.rm=T), line = 2.5, col = 'gray50')
mtext("(c)", 2, at = .018, cex = 2, outer = F, las = 1, line = 3)

# empirical value
abline(h = seb.PSV.rich.slope, lty = empirical.lty, lwd = empirical.lwd)


## (d) MRD-richness slope
# zero sum results
plot(trop.metrics.mean$time/1000, trop.metrics.mean[, 'scaled.MRD.rich.slope'], xlim = c(0, max(trop.metrics.mean$time, na.rm=T)/1000), 
     ylim = c(-0.01, 0.008), type = "n",
     ylab = metric.labels[metric.names == 'scaled.MRD.rich.slope'], xlab = "", yaxt = "n")
axis(2, at = c(-.01, -.005, 0, .005), labels = c(-10, -5, 0, 5))
polygon(c(trop.metrics.mean$time/1000, rev(trop.metrics.mean$time/1000)), 
        c(trop.metrics.mean[, 'scaled.MRD.rich.slope'] - error*trop.metrics.sd[, 'scaled.MRD.rich.slope'], 
          rev(trop.metrics.mean[, 'scaled.MRD.rich.slope'] + error*trop.metrics.sd[, 'scaled.MRD.rich.slope'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(temp.metrics.mean$time/1000, rev(temp.metrics.mean$time/1000)), 
        c(temp.metrics.mean[, 'scaled.MRD.rich.slope'] - error*temp.metrics.sd[, 'scaled.MRD.rich.slope'], 
          rev(temp.metrics.mean[, 'scaled.MRD.rich.slope'] + error*temp.metrics.sd[, 'scaled.MRD.rich.slope'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(trop.metrics.mean$time/1000, trop.metrics.mean[, 'scaled.MRD.rich.slope'], type = 'l', col = 'red', lwd = 3)
points(temp.metrics.mean$time/1000, temp.metrics.mean[, 'scaled.MRD.rich.slope'], type = 'l', col = 'blue', lwd = 3)

# vertical line at equilibrium time point
abline(v = eq.time)

par(new = T)

# non-zero-sum results
plot(Ttemp.metrics.mean$time - x.offset, Ttrop.metrics.mean[, 'scaled.MRD.rich.slope'], 
     xlim = c(0, max(c(Ttrop.metrics.mean$time, Ttemp.metrics.mean$time), na.rm = T) - x.offset), 
     ylim = c(-0.01, 0.008), type = "n",
     ylab = "", xlab = "", yaxt = "n", xaxt = "n")
polygon(c(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), rev(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T))), 
        c(Ttrop.metrics.mean[, 'scaled.MRD.rich.slope'] - error*Ttrop.metrics.sd[, 'scaled.MRD.rich.slope'], 
          rev(Ttrop.metrics.mean[, 'scaled.MRD.rich.slope'] + error*Ttrop.metrics.sd[, 'scaled.MRD.rich.slope'])), 
        col = rgb(.8, 0, 0, .3), border = NA)
polygon(c(Ttemp.metrics.mean$time - x.offset, rev(Ttemp.metrics.mean$time - x.offset)), 
        c(Ttemp.metrics.mean[, 'scaled.MRD.rich.slope'] - error*Ttemp.metrics.sd[, 'scaled.MRD.rich.slope'], 
          rev(Ttemp.metrics.mean[, 'scaled.MRD.rich.slope'] + error*Ttemp.metrics.sd[, 'scaled.MRD.rich.slope'])), 
        col = rgb(0, 0, .8, .3), border = NA)
points(Ttrop.metrics.mean$time - min(Ttrop.metrics.mean$time, na.rm = T), Ttrop.metrics.mean[, 'scaled.MRD.rich.slope'], type = 'l', col = 'red', lwd = 3, lty = 'dashed')
points(Ttemp.metrics.mean$time - x.offset, Ttemp.metrics.mean[, 'scaled.MRD.rich.slope'], type = 'l', col = 'blue', lwd = 3, lty = 'dashed')
alt.x.vals = c(120, 140, 160, 180)
#mtext(alt.x.vals, 1, at = alt.x.vals - min(Ttemp.metrics.mean$time, na.rm=T), line = 2.5, col = 'gray50')
mtext("(d)", 2, at = .01, cex = 2, outer = F, las = 1, line = 3)

# empirical value
abline(h = seb.MRD.rich.slope.scaled, lty = empirical.lty, lwd = empirical.lwd)


mtext("Time", 1, outer=T, cex = 1.3, line = 0) 
#mtext("Time (no zero sum)", 1, outer = T, cex = 1.3, line = 1.25, col = 'gray50')
dev.off()

