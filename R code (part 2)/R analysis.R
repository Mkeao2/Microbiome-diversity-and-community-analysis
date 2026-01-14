#==============================================================================
#Does phylogeny impact alpha diversity?
#==============================================================================
library("ggplot2")
library("phytools")
#look at unique genus names and put in order for plot
unique(data$BeeGenus)
data$BeeGenus <- factor(data$BeeGenus, levels = c("Augochorella","Agapostemon", "Lasioglossum","Halictus ","Bombus", "Ceratina", "Melissodes", "Anthidium","Pseudoanthidium", "Heriades ", "Megachile"))

#make trimmed version of tree to show only genus level
species <- c("Bombus_rufocinctus", "Ceratina_calcarata", "Lasioglossum_lineatulum", "Megachile_latimanus", "Augochlorella_aurata", "Agapostemon_virescens", "Halictus_rubicundus", "Anthidium_oblongatum", "Pseudoanthidium_nanum", "Heriades_leavitti", "Melissodes_subillatus")

pruned.tree<-drop.tip(bee.tree, setdiff(bee.tree$tip.label, species)) #note I imported the tree outsdie of this script
plot(pruned.tree)

#alpha diversity 

Wide_data2 <- dcast(data, variable + Prop.Urban + Site + BeeFamily + BeeGenus + BeeSpecies ~ Family.or.genus, value.var = "Proportion", fun.aggregate = length)  
Wide_data2[is.na(Wide_data2)] <- 0
poll = Wide_data2[,7:77]

alpha_shannon <- diversity(poll, index = "shannon")    
alpha_shannon_data<- as.data.frame(alpha_shannon)

Wide_data3 <- bind_cols(alpha_shannon_data, Wide_data2)

#make tree plot with node numbers - use this website for help https://4va.github.io/biodatasci/r-ggtree.html

tree.plot <- ggtree(pruned.tree) + geom_text(aes(label=node), hjust=-.3)

tree.plot <- ggtree(pruned.tree) + 
  geom_hilight(node=17, fill="gold") + 
  geom_hilight(node=20, fill="purple") + 
  geom_hilight(node=13, fill="blue") 

#make base plot and add tree plot

Wide_data3$BeeGenus <- factor(Wide_data3$BeeGenus, levels = c("Augochorella","Agapostemon","Lasioglossum","Halictus","Bombus", "Ceratina","Melissodes","Anthidium","Pseudoanthidium","Heriades"))

Wide_data3 %>%
  ggplot(aes(x = PlantSpecies, y = alpha_shannon, color = PlantSpecies)) +
  geom_boxplot() +
  coord_flip() + 
  scale_colour_viridis_d() 

#statistical test 
data4 <- Wide_data3 %>%
  group_by(BeeSpecies) %>%
  mutate(alpha_mean = mean(alpha_shannon))

data5 <- data4[-c(1,3)] #pretty sure this just removed grouping columns
data6 <- distinct(data5) #makes a dataframe with only unique rows
data6 <- as.data.frame(data6)
data6$dupe <- data6$BeeSpecies #this line and the next make column names row name
data7 <- data6 %>% remove_rownames %>% column_to_rownames(var="dupe") 


compare <- comparative.data(bee.tree, data7, BeeSpecies)

pglsModel <- pgls(alpha_mean ~ BeeFamily, compare, param.CI = 0.95)
summary(pglsModel)

#==============================================================================
#Does impervious surface impact alpha diversity?
#==============================================================================
library("lme4")
library("lmerTest")
library("car")

#subset groups (only if you want to see results separately for different taxa)
widefungi$Site <- as.factor(widefungi$Site)

Arvense <- widefungi%>% filter(PlantSpecies == "arvense")
Intybus <-  widefungi%>% filter(PlantSpecies == "intybus")
lappa <-  widefungi%>% filter(PlantSpecies == "lappa")
Vulgare <-  widefungi%>% filter(PlantSpecies == "vulgare")

Arvense.mod <- lmer(alpha_shannon ~ Prop.Urban + (1|Site), dat=Arvense)
Intybus.mod <- lmer(alpha_shannon ~ Prop.Urban + (1|Site), dat=Intybus)
lappa.mod <- lmer(alpha_shannon ~ Prop.Urban + (1|Site), dat=lappa)
Vulgare.mod <- lmer(alpha_shannon ~ Prop.Urban + (1|Site), dat=Vulgare)

effects.Arvense.mod  <- effects::effect(term= "Prop.Urban", mod= Arvense.mod)
effects.Intybus.mod  <- effects::effect(term= "Prop.Urban", mod= Intybus.mod)
effects.lappa.mod  <- effects::effect(term= "Prop.Urban", mod= lappa.mod)
effects.Vulgare.mod  <- effects::effect(term= "Prop.Urban", mod= Vulgare.mod)

effects.Arvense.mod.data <- as.data.frame(effects.Arvense.mod)
effects.Intybus.mod.data <- as.data.frame(effects.Intybus.mod)
effects.lappa.mod.data <- as.data.frame(effects.lappa.mod)
effects.Vulgare.mod.data <- as.data.frame(effects.Vulgare.mod)

fungi.Arvense<-  ggplot() +
  geom_point(data=Arvense, aes(Prop.Urban, alpha_shannon), color="#440154FF") +
  geom_point(data=effects.Arvense.mod.data, aes(x=Prop.Urban, y=fit), color="#440154FF") +
  geom_line(data=effects.Arvense.mod.data, aes(x=Prop.Urban, y=fit), color="#440154FF") +
  geom_ribbon(data=effects.Arvense.mod.data, aes(x=Prop.Urban, ymin=lower, ymax=upper), alpha= 0.1, fill="#440154FF") +
labs(x="Impervious surface area", y="Bacteria alpha diversity") 

fungi.Intybus <-  ggplot() +
  geom_point(data=Intybus, aes(Prop.Urban, alpha_shannon), color="#2A788EFF") +
  geom_point(data=effects.Intybus.mod.data, aes(x=Prop.Urban, y=fit), color="#2A788EFF") +
  geom_line(data=effects.Intybus.mod.data, aes(x=Prop.Urban, y=fit), color="#2A788EFF") +
  geom_ribbon(data=effects.Intybus.mod.data, aes(x=Prop.Urban, ymin=lower, ymax=upper), alpha= 0.1, fill="#2A788EFF") +
labs(x="Impervious surface area", y="Bacteria alpha diversity") 

fungi.lappa <-  ggplot() +
  geom_point(data=lappa, aes(Prop.Urban, alpha_shannon), color="#7AD151FF") +
  geom_point(data=effects.lappa.mod.data, aes(x=Prop.Urban, y=fit), color="#7AD151FF") +
  geom_line(data=effects.lappa.mod.data, aes(x=Prop.Urban, y=fit), color="#7AD151FF") +
  geom_ribbon(data=effects.lappa.mod.data, aes(x=Prop.Urban, ymin=lower, ymax=upper), alpha= 0.2, fill="#7AD151FF") +
  labs(x="Impervious surface area", y="Bacteria alpha diversity") 

fungi.Vulgare <-  ggplot() +
  geom_point(data=Vulgare, aes(Prop.Urban, alpha_shannon), color="black") +
  geom_point(data=effects.Vulgare.mod.data, aes(x=Prop.Urban, y=fit), color="#414487FF") +
  geom_line(data=effects.Vulgare.mod.data, aes(x=Prop.Urban, y=fit), color="#414487FF") +
  geom_ribbon(data=effects.Vulgare.mod.data, aes(x=Prop.Urban, ymin=lower, ymax=upper), alpha= 0.1, fill="#414487FF") 


fungi.Arvense<- fungi.Arvense+ rremove("xylab") 
fungi.Vulgare<- fungi.Vulgare + rremove("xylab") 
fungi.lappa <- fungi.lappa+ rremove("xylab") 
fungi.Intybus<- fungi.Intybus + rremove("xylab") 


figure <- ggarrange(fungi.Bombus, fungi.Apidae, fungi.Halictidae, fungi.lappa,
                    ncol = 2, nrow = 2) + rremove("grid")

annotate_figure(figure,
                #  top = text_grob("Bee", color = "black", face = "bold", size = 14),
                bottom = text_grob("Impervious surface area", color = "black"),
                left = text_grob("Shannon Diversity", color = "black", rot = 90),
)


summary(lappa.mod)
Anova(lappa.mod, confint = TRUE)
confint(lappa.mod, method = "Wald", level=0.95)

#==============================================================================
#Do certain categorical and continuous variables impact community makeup ?
#==============================================================================
install_github("pmartinezarbizu/pairwiseAdonis/pairwiseAdonis")
library("ggplot2")
library("vegan")
library("pairwiseAdonis")

#beta diversity, nmds
#gets rid of variable columns
poll = widefungi[,3:71]
#transformation
poll2 <- decostand(poll, method = "hellinger")


nmds = metaMDS(poll)
#examine how well your data fits the model.
stressplot(nmds) 
#make sure you don't have any crazy outliers that need to be removed or that you don't 
#have a factor that requires you to put your data in two different plots. 
plot(nmds)

#extract data scores, note that "sites" should always be listed as this is just the 
#command terminology and not anything to do with an actual site variable. 
data.scores = as.data.frame(vegan::scores(nmds)$sites)

#assign explanatory variables to join their point coordinates
data.scores$PlantSpecies = widefungi$PlantSpecies
data.scores$BeeFamily = widefungi$BeeFamily
data.scores$BeeSpecies = widefungi$BeeSpecies
data.scores$Impervious_surface = widefungi$Impervious_surface

#Is the data normally distributed?
#If yes, use stat_ellipse. If not, use mark_stat_ellipse. 
#Note that this is your abundance data before you transform to a wide dataset.
ggdensity(fungi$Proportion, xlab = "Proportion of Impervious Surface")

#note that you may need a couple of different plots to include all the variables you want
ggplot() + 
  geom_point(data.scores, mapping=aes(x = NMDS1, y = NMDS2, color = BeeFamily, shape = BeeGenus), size = 5, position=position_jitter(width=0.3)) +
  geom_mark_ellipse(data.scores, mapping = aes(x = NMDS1, y = NMDS2, fill = PlantSpecies, label = PlantSpecies), alpha = 0) +
  scale_colour_gradient(low = "yellow", high = "red") + #only include this line if you have a continuous variable.
  theme_bw() + scale_color_viridis(discrete = TRUE, option = "D") +
  theme(panel.border = element_blank(), panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"))


#PERMANOVA
adonis2(poll2 ~ BeeFamily + BeeGenus + Impervious_surface, data = widefungi, permutations = 999, method = "bray", na.rm = TRUE) 

#pairwise comparisons if you get a significant result
pairwise.adonis(poll2, widefungi$BeeFamily, perm = 9999)

#==============================================================================
#Which genera are in the top x?
#==============================================================================
#abundance plots

#makes a table that you can sort by hand in the data frame viewer. record these in the next step
counts <- table(Fungi$Genus)
counts <- as.data.frame(counts)
counts

#limit to top ten genera in the above list - make sure filtering column is a character
widebacteria <- widebacteria[Fungi$Genus=="Apilactobacillus"Fungi$Genus=="Arsenophonus"|Fungi$Genus=="Pantoea"|Fungi$Genus=="Snodgrassella"|Fungi$Genus=="Saccharibacter"|Fungi$Genus=="Enterobacter"|Fungi$Genus=="Philodulcilactobacillus"|Fungi$Genus=="Pseudomonas"|Fungi$Genus=="Gilliamella"|Fungi$Genus=="Enterococcus",]

#make factor and rder by the most common taxa (this will guide the legend in the plot)
Fungi$Genus <- as.factor(Fungi$Genus)
Fungi$Genus <- fct_relevel(Fungi$Genus, "Apilactobacillus", "Arsenophonus", "Pantoea", "Snodgrassella", "Saccharibacter", "Enterobacter", "Philodulcilactobacillus", "Pseudomonas", "Gilliamella", "Enterococcus")

#put samples in correct order for x axis
Fungi$Sample <- as.factor(Fungi$Sample)
Fungi$Sample<- fct_relevel(Fungi$Sample, "M.fortis1",
                                "M.fortis2",
                                "M.fortis3",
                                "M.latimanus1",
                                ...)
#plot                             
ggplot(Fungi, aes(fill=Genus, y=Proportion, x=Sample)) +
  geom_bar(position="fill", stat="identity") +
  theme(axis.text.x = element_text(angle = 90), axis.text = element_text(face="italic", hjust = 1), axis.ticks.x=element_blank(),
        legend.text=element_text(face="italic"), theme_void()) +
  scale_fill_viridis_d()

#==============================================================================
#How do many different variables impact microbial communities?
#==============================================================================
#RDA https://r.qcbs.ca/workshop10/book-en/redundancy-analysis.html

#define species columns (bacteria/fungi) and environmental variable columns (bee family, temp, precip, etc)
species=decostand(RDAbacteria[9:96], method = "hellinger")
environment=RDAbacteria[1:8] 

#Fit full model with all terms
RDA <- rda(species ~ BeeFamily + BeeGenus + PlantSpecies + Prec_mean + Impervious_surface + avg_temp, environment, dist="bray")
species[is.na(species)] <- 0
plot(RDA)
summary(RDA)

#see the best model from all terms
ordiR2step(rda(species ~ 1, data = environment, direction = c("forward")), # lower model limit (simple!)
           scope = formula(RDA), # upper model limit (the "full" model)
           direction = "forward",
           R2scope = TRUE, # can't surpass the "full" model's R2
           pstep = 1000,
           trace = TRUE) 


#what is the new R2 for the final model?
spe.rda.signif <- rda(species ~ BeeGenus + PlantSpecies + Prec_mean + tavg_mean, data = environment)

#view model, term, and axis significance from original model
#can also look at best model above
anova.cca(RDA, step = 1000)
anova.cca(RDA, step = 1000, by = "term")
anova.cca(RDA, step = 1000, by = "axis")

# check the adjusted R2 (corrected for the number of
# explanatory variables)
RsquareAdj(spe.rda.signif)

#get data scores like we did for NMDS, but must split up rows into different categories
#you also need to keep track of any biplot scores for arrows you want on the plot (we
#will put these in manually)
data.scores <- fortify(RDA, axes = 1:2)
centroid.scores <- data.score.fungi[314:348,]
sample.scores <- data.score.fungi[69:176,] 
species.scores <- data.score.fungi[1:68,]

#add explanatory variables back in
sample.scores$BeeFamily = RDAfungi$BeeFamily
sample.scores$BeeGenus = RDAfungi$BeeGenus
sample.scores$PlantSpecies = RDAfungi$PlantSpecies 
sample.scores$Prop.Urban = RDAfungi$Impervious_surface

#plot sample, species, and centroid scores seperately 
ggplot() + 
  geom_point(sample.scores, mapping=aes(x = RDA1, y = RDA2, colour = Prop.Urban, shape = PlantSpecies), size = 3, position=position_jitter(width=.3)) +
  geom_point(centroid.scores, mapping=aes(x = RDA1, y = RDA2), color = "gray", size = 1.5) +
  geom_point(species.scores, mapping=aes(x = RDA1, y = RDA2), color = "black", size = 1.5) +
  # this is where you add in the coordinates from your biplot scores to plot the arrows
  geom_segment(mapping=aes(x = 0, y = 0, xend = -0.5840831, yend = 0.03663513), arrow = arrow(length = unit(0.5, "cm"))) + 
  geom_segment(mapping=aes(x = 0, y = 0, xend = 0.4335986, yend = -0.11228067), arrow = arrow(length = unit(0.5, "cm"))) + 
  geom_segment(mapping=aes(x = 0, y = 0, xend = -0.3687583, yend = 0.2228215), arrow = arrow(length = unit(0.5, "cm"))) + 
  geom_vline(xintercept = 0, linetype= "dashed") +
  geom_hline(yintercept=0, linetype="dashed") +
  scale_shape_manual(values = c(1:8,15, 17:18, 22:25)) + 
  theme_bw() + 
  scale_color_viridis(discrete = TRUE, option = "D") +
  theme(panel.border = element_blank(), panel.grid.major = element_blank(),                #only include the below line if you want a continuous variable gradient
        panel.grid.minor = element_blank(), axis.line = element_line(colour = "black")) #+ scale_colour_gradient(low = "yellow", high = "red")
