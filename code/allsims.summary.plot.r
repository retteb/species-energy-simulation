# Evaluating relationship between simulation output correlations and simulation parameters

file_dir = '//bioark.bio.unc.edu/hurlbertallen/manuscripts/cladevscommunity/analyses/summaryplots'

#sim.rs = compile.firstlines(file_dir , "SENC_Stats_sim")          #takes ~12 minutes on Hurlbert office machine
#write.csv(sim.rs,paste(file_dir,'/allsims_bigclade_stats_output.csv',sep=''), row.names=F)

sim.rs = read.csv(paste(file_dir,'/allsims_bigclade_stats_output.csv',sep=''), header=T)
sim.matrix = read.csv(paste(file_dir,'/sim.matrix.output_2012-12-20.csv',sep=''), header=T)
# warning: sim.matrix.output_2012-12-20.csv currently messed up (all text entries changed to '1')
# I replaced first 11 columns with older sim.matrix.output file

# Set alpha and beta to explore variation in other axes of parameter space; 
Alpha = 1e-6
Beta = 1e-4

# exclude case with energy gradient but no carrying capacity
sim.matrix.sm = subset(sim.matrix, alpha == Alpha & beta == Beta & !(carry.cap=="off" & energy.gradient=="on"), 
                       select = c('sim.id','reg.of.origin','w','sigma_E','carry.cap','energy.gradient'))

sim.big = merge(sim.matrix.sm, sim.rs, by.x="sim.id", by.y="sim", all.x=T)
sim.big = sim.big[sim.big$sim.id!=0,]

sim.big$log.BK.env = log10(sim.big$BK.env)
sim.big$log.BK.reg = log10(sim.big$BK.reg)

# Within each combination of w and sigma, space out simulations along x-axis based
# on carry.cap/energy.gradient and along y-axis based on reg.of.origin
x.offset = .5
y.offset = .25
label.offset = .5

f1 = function(x) {
  if(sim.big[x,'carry.cap']=="on" & sim.big[x,'energy.gradient']=="on") {
     y = sim.big[x,'w'] - x.offset
  }
  if(sim.big[x,'carry.cap']=="off" & sim.big[x,'energy.gradient']=="off") {
    y = sim.big[x,'w'] + x.offset
  }
  if (sim.big[x,'carry.cap']=="on" & sim.big[x,'energy.gradient']=="off") {
    y = sim.big[x,'w']
  }
  return(y)
}
sim.big$w.K = sapply(1:nrow(sim.big), f1)

f2 = function(x, y.offset) {
  if(sim.big[x,'reg.of.origin']=='tropical') {
    y = sim.big[x,'sigma_E'] + y.offset
  }
  if(sim.big[x,'reg.of.origin']=='temperate') {
    y = sim.big[x,'sigma_E'] - y.offset
  }
  return(y)
}
sim.big$sigma.reg = sapply(1:nrow(sim.big), function(x) f2(x, y.offset))

sim.big$label.y = sapply(1:nrow(sim.big), function(x) f2(x, label.offset))

sim.big$symbol = 16
sim.big[sim.big$reg.of.origin=='temperate','symbol'] = 17

# List of independent variables to plot (using color)
yvars = c('r.time.rich','r.env.rich','r.MRD.rich','r.PSV.rich','r.env.MRD',
          'r.env.PSV','r.ext.reg','r.rich.ext','log.BK.env','log.BK.reg')


# Plots are on sigma_E versus w space, with color reflecting yvars (list above)
# TO DO: Need a legend still

summary.plot = function(sim.big, yvars, file_dir) {
  colors = colorRampPalette(c('red','pink','white','skyblue','darkblue'))(201)
  
  pdf(paste(file_dir,'/summary_plots_alpha_',Alpha,'_beta_',Beta,'.pdf',sep=''),height=6,width=8)
  par(mar = c(4,4,4,1))
  for (i in yvars) {
    y = sim.big[,which(names(sim.big)==i)]
    if (i %in% c('log.BK.env','log.BK.reg')) {
      col.index = round(y,2)*50 + 100 #color scale ranges from BK values of -2 to 2
    } else {
      col.index = round(y,2)*100 + 100 #color scale for correlations from -1 to 1
    }
    plot(sim.big$w.K, sim.big$sigma.reg, pch = sim.big$symbol, xlab = "<--- Environmental Filtering",
         ylab="<--- Niche Conservatism",col=colors[col.index], 
         main = paste("alpha = ",Alpha,"; beta = ",Beta,"; color = ",i,sep=''), cex=2, ylim = c(.5,12.5))
    text(sim.big$w.K, sim.big$label.y, sim.big$sim.id, cex=.4)
    mtext("red - , blue +",3,line=0.5)
    text(x=c(10.2,11.1,11.7),y=rep(12.25,3),c('K\ngradient','K\nconstant','no\nK'), cex = 0.75)
    legend("topleft",pch=c(16,17),c('tropical origin','temperate origin'), cex = 0.75, bty = "n")
    segments(x0 = c(11-x.offset, 11, 11+x.offset), y0 = 11.2+y.offset, x1 = c(10.2,11.1,11.7), y1 = 11.8)
  }
  dev.off()
}

