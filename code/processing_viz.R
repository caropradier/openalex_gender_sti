library(tidyverse)
library(viridis)
library(patchwork)
library(readxl)
library(countrycode)
library(wesanderson)
library(ggridges)
library(ggrepel)

options(scipen =9999)

####domains and regions######

gender_frac_year <- read_excel("data/sql_results.xlsx", 
                               sheet = "gender_frac_year") %>% 
  mutate(domain = "All")


#methods check
gender_frac_year %>% 
  filter(publication_year <= 2024) %>% 
  filter(gender == "Women") %>% 
  summarise(n = sum(total_work_count))

dis_frac_year <- read_excel("data/sql_results.xlsx", 
                            sheet = "dis_frac_year")

domain_authorship <- dis_frac_year %>% 
  bind_rows(gender_frac_year) %>% 
  filter(domain != "No data") %>% 
  filter(gender == "Women") %>% 
  filter(publication_year <= 2024) %>% 
  ggplot(aes(x = publication_year, 
             y = prop_works, 
             color = domain))+
  geom_line(size = 1)+
  scale_y_continuous(labels = function(x) paste0(x*100,"%"))+
  theme_minimal()+
  scale_fill_brewer(palette = "Dark2")+
  geom_hline(yintercept = .5, linewidth = .1)+
  geom_hline(yintercept = .25, linewidth = .1)+
  theme(legend.position = c(.25,.8))+
  scale_color_manual(values = c("black",wes_palette("Darjeeling1")))+
  labs(x = "Publication year",
       y = "% Women authorship",
       color = "",
       title = "A")+
  guides(color = guide_legend(nrow = 5))


gender_frac_year <- read_excel("data/sql_results.xlsx", 
                               sheet = "gender_frac_year") %>% 
  mutate(continent = "All") %>% 
  mutate(alpha = sum(total_work_count))


country_frac_year <- read_excel("data/sql_results.xlsx", 
                                sheet = "country_frac_year") %>% 
  mutate(country_code = countrycode(country,'country.name', 'iso2c')) %>% 
  mutate(country_code = case_when(
    country == "Kosovo" ~"XK",
    country == "Micronesia" ~"FM",
    TRUE ~country_code
  )) %>% 
  mutate(continent = countrycode(sourcevar = country_code,
                                 origin = "iso2c",
                                 destination = "un.regionsub.name")) %>% 
  mutate(continent = case_when(continent %in% c("Melanesia","Micronesia","Polynesia","Australia and New Zealand") ~"Oceania",
                               country_code == "TW" ~ "Eastern Asia",
                               country_code == "XK" ~ "Eastern Europe",
                               TRUE ~ continent)) 


region_table <- country_frac_year %>% 
  filter(publication_year > 1960) %>% 
  filter(publication_year <= 2024) %>% 
  filter(continent != "Central Asia") %>% 
  group_by(continent,publication_year,gender) %>% 
  summarise(work_count = sum(work_count,na.rm = T)) %>% 
  ungroup() %>% 
  group_by(continent,publication_year) %>% 
  mutate(total_work_count = sum(work_count)) %>% 
  ungroup() %>% 
  mutate(prop_works = work_count/total_work_count) %>% 
  group_by(continent) %>% 
  mutate(alpha = sum(total_work_count)) %>% 
  filter(total_work_count > 100) %>% 
  ungroup() %>% 
  bind_rows(gender_frac_year) %>% 
  filter(gender == "Women") %>% 
  mutate(continent = ifelse(continent == "Latin America and the Caribbean","Latin America and\n      the Caribbean",continent))

region_colors <- c(
  "Eastern Europe"                  = "#9467BD",
  "Latin America and\n      the Caribbean" = "#E377C2",
  "Eastern Asia"              = "#D62728",
  "Central Asia"              = "#CD5B45",
  "Northern Africa"                 = "#BCBD22",
  "Northern America"                = "#7F7F7F",
  "Northern Europe"                 = "#4F81BD",
  "Oceania"                         = "#4E9A51",
  "South-eastern Asia"              = "#B35400",
  "Southern Asia"                   = "#C97A2B",
  "Southern Europe"                 = "#1F77B4",
  "Sub-Saharan Africa"              = "#2CA02C",
  "Western Asia"                    = "#FFD92F",
  "Western Europe"                  = "#17BECF",
  "All" = "black"
)




region_plot <- region_table %>% 
  ggplot(aes(x = publication_year, y = prop_works, color = reorder(continent,-alpha), alpha = alpha))+
  geom_line(size = 1)+
  geom_text_repel(data = region_table %>% 
                    filter(publication_year == 2024) ,
                  aes(color = continent, 
                      label = continent),
                  size = 3,
                  fontface = "bold",
                  direction = "y",
                  segment.linetype = "dotted",
                  segment.alpha = .5,
                  xlim = c(2028.5, NA),
                  hjust = -1.8
  ) +
  geom_hline(yintercept = .5, size = .1)+
  geom_hline(yintercept = .25, linewidth = .1)+
  theme_minimal()+
  scale_color_manual(values = region_colors)+
  scale_y_continuous(labels = function(x) paste0(x*100,"%"))+
  scale_alpha_continuous(range = c(.7,1))+
  theme(legend.position = "none")+
  theme(plot.margin = margin(5.5, 106, 5.5, 5.5))+
  coord_cartesian(clip = "off") +
  
  labs(x = "Publication year", 
       y = "% Women authorship",
       color="Region",
       title = "B")+
  guides(alpha = "none")


domain_authorship + region_plot

ggsave("results/description_region_discipline.png",bg="white",height = 6,width = 10)


####composition######


region_sex_colors <- c(
  "Eastern Europe - Men"                    = "#9467BD",
  "Eastern Europe - Women"                  = "#5B3A82",
  "Latin America and the Caribbean - Men"   = "#E377C2",
  "Latin America and the Caribbean - Women" = "#A64D79",
  "Eastern Asia - Men"                = "#D62728",
  "Eastern Asia - Women"              = "#7B1E1E",
  "Central Asia - Men"                = "#FF7F50",
  "Central Asia - Women"              = "#CD5B45",
  "Northern Africa - Men"                   = "#BCBD22",
  "Northern Africa - Women"                 = "#6B6E00",
  "Northern America - Men"                  = "#7F7F7F",
  "Northern America - Women"                = "#4D4D4D",
  "Northern Europe - Men"                   = "#AEC7E8",
  "Northern Europe - Women"                 = "#4F81BD",
  "Oceania - Men"                           = "#98DF8A",
  "Oceania - Women"                         = "#4E9A51",
  "South-eastern Asia - Men"                = "#FF7F0E",
  "South-eastern Asia - Women"              = "#B35400",
  "Southern Asia - Men"                     = "#FFBB78",
  "Southern Asia - Women"                   = "#C97A2B",
  "Southern Europe - Men"                   = "#1F77B4",
  "Southern Europe - Women"                 = "#0B3C5D",
  "Sub-Saharan Africa - Men"                = "#2CA02C",
  "Sub-Saharan Africa - Women"              = "#145A32",
  "Western Asia - Men"                      = "#FFD92F",
  "Western Asia - Women"                    = "#B79F00",
  "Western Europe - Men"                    = "#17BECF",
  "Western Europe - Women"                  = "#0E6F7F"
)




group_order <- country_frac_year %>% 
  filter(publication_year > 1960) %>% 
  filter(publication_year <2025) %>% 
  group_by(continent,publication_year,gender) %>% 
  summarise(work_count = sum(work_count,na.rm = T)) %>% 
  group_by(publication_year) %>% 
  mutate(p = work_count/sum(work_count)) %>% 
  mutate(group = paste0(continent, " - ", gender)) %>% 
  group_by(continent) %>% 
  summarise(work_count = sum(work_count)) %>% 
  arrange(-work_count) %>% 
  pull(continent)

group_order_sex <- as.vector(t(outer(group_order, c("Men", "Women"), paste, sep = " - ")))


stacked <- country_frac_year %>% 
  filter(publication_year > 1960) %>% 
  filter(publication_year <2025) %>% 
  group_by(continent,publication_year,gender) %>% 
  summarise(work_count = sum(work_count,na.rm = T)) %>% 
  group_by(publication_year) %>% 
  mutate(p = work_count/sum(work_count)) %>% 
  mutate(group = paste0(continent, " - ", gender)) %>% 
  mutate(group = factor(group, levels=rev(group_order_sex))) %>% 
  ggplot(aes(x = publication_year, y =p,group = group, fill = group))+
  geom_area()+
  geom_hline(yintercept = .5,size=.1)+
  scale_fill_manual(values = region_sex_colors,labels = function(x) str_wrap(x,25))+
  theme_minimal()+
  labs(fill = "")+
  scale_y_continuous(labels = function(x) paste0(x*100,"%"))+
  labs(x = "Publication year", 
       y = "% Authorship"
       ,title = "A"
  )+
  guides(fill = guide_legend(ncol = 1))


top_regions <- group_order[1:4]

top_table <- country_frac_year %>% 
  filter(publication_year > 1960) %>% 
  filter(publication_year <2025) %>% 
  group_by(continent,publication_year,gender) %>% 
  summarise(work_count = sum(work_count,na.rm = T)) %>% 
  group_by(publication_year) %>% 
  mutate(p = work_count/sum(work_count)) %>% 
  mutate(group = paste0(continent, " - ", gender)) %>% 
  mutate(group = factor(group, levels=rev(group_order_sex))) %>% 
  filter(continent %in% top_regions) %>% 
  mutate(group_label = str_replace(group," - ", "\n                 "))

lines <- top_table %>% 
  ggplot(aes(x = publication_year, y =p,group = group, color = group))+
  geom_line(size = 1)+
  geom_text_repel(data = top_table %>% 
                    filter(publication_year == 2024) ,
                  aes(color = group, 
                      label = group_label),
                  size = 3,
                  fontface = "bold",
                  direction = "y",
                  segment.linetype = "dotted",
                  segment.alpha = .5,
                  xlim = c(2028.5, NA),
                  hjust = 0
                  ,nudge_x = 10.5
  ) +
  scale_color_manual(values = region_sex_colors,NULL)+
  theme_minimal()+
  theme(legend.position = "none")+
  labs(color = "")+
  scale_y_continuous(labels = function(x) paste0(x*100,"%"))+
  labs(x = "Publication year", 
       y = "% Authorship"
       ,title = "B"
  )+
  guides(fill = guide_legend(ncol = 1))+
  theme(plot.margin = margin(5.5, 106, 5.5, 5.5))+
  coord_cartesian(clip = "off")

lines

stacked+lines+plot_layout(widths = c(.6,.4))

ggsave("results/stacked_lines_women_frac_evolution.png",bg="white",height = 8,width = 14)


####FWCI regions#####

aux_country_year <- read_excel("data/sql_results.xlsx", 
                               sheet = "country_frac_year") %>% 
  select(publication_year,country,total_work_count) %>% unique() %>% 
  mutate(country_code = countrycode(country,'country.name', 'iso2c')) %>% 
  mutate(country_code = case_when(
    country == "Kosovo" ~"XK",
    country == "Micronesia" ~"FM",
    TRUE ~country_code
  )) %>% 
  mutate(continent = countrycode(sourcevar = country_code,
                                 origin = "iso2c",
                                 destination = "un.regionsub.name")) %>% 
  mutate(continent = case_when(continent %in% c("Melanesia","Micronesia","Polynesia","Australia and New Zealand") ~"Oceania",
                               country_code == "TW" ~ "Eastern Asia",
                               country_code == "XK" ~ "Eastern Europe",
                               TRUE ~ continent)) %>% 
  group_by(publication_year,continent) %>% 
  summarise(tot = sum(total_work_count)) %>% 
  ungroup()

region_order <- aux_country_year %>% 
  group_by(continent) %>% 
  summarise(n = sum(tot)) %>% 
  arrange(n) %>% pull(continent)


citation_evolution_regions <- read_excel("data/sql_results.xlsx", 
                                         sheet = "fwci_first_author_region")



country_plot <- citation_evolution_regions %>% 
  left_join(aux_country_year, by = c("continent","publication_year")) %>% 
  mutate(continent = factor(continent,levels=rev(region_order))) %>% 
  filter(publication_year <=2024) %>% 
  ggplot(aes(x=publication_year, y=weighted_avg_norm_citations, 
             size = tot,
             fill=gender,
             color = gender))+
  geom_point(alpha= .7)+
  geom_smooth()+
  geom_hline(yintercept = 1, size = .2)+
  scale_size(range=c(1,8))+
  scale_color_manual(values = RColorBrewer::brewer.pal("Spectral", n = 11)[c(9,1)])+
  scale_fill_manual(values = RColorBrewer::brewer.pal("Spectral", n = 11)[c(9,1)])+
  theme_minimal()+
  theme(legend.text = element_text(size =12))+
  theme(strip.text.x = element_text(size =12))+
  theme(legend.position = c(.9,.2))+
  guides(size = "none",
         color = guide_legend(ncol = 1))+
  facet_wrap(~continent,scales="free",
             ncol=5
             ,labeller = label_wrap_gen(width = 20))+
  labs(color = "",fill="",
       x = "Publication year", y ="Average Field-Weighted Citation Impact"
  )

country_plot

ggsave("results/fwci_gender_countries.png",bg="white",height = 8,width = 12)



control <- read_excel("data/sql_results.xlsx", 
                      sheet = "fwci_gap_nodisag") %>% 
  filter(publication_year <2025) %>% 
  pivot_wider(id_cols = c("publication_year"), names_from = "gender", values_from = "weighted_avg_norm_citations") %>% 
  mutate(gap = (Men-Women)/Men)


aggregate_plot <- control %>% 
  ggplot(aes(x = publication_year, y = gap))+
  geom_point()+
  geom_point(alpha= .7, color = "black")+
  geom_smooth(alpha =.3, color = "black",
              fill = "black")+
  scale_y_continuous(labels = function(x) paste0(x*100,"%"))+
  geom_hline(yintercept = 0, size = .2)+
  labs(x = "Publication year", 
       y ="Average FWCI gap"
       ,title = "A")+
  theme_minimal()

gaps <- citation_evolution_regions %>% 
  pivot_wider(id_cols = c("continent","publication_year"), 
              names_from = gender, values_from = weighted_avg_norm_citations) %>%
  mutate(gap = (Men-Women)/Men) %>% 
  left_join(aux_country_year, by = c("continent","publication_year")) %>% 
  mutate(continent = factor(continent,levels=rev(region_order))) %>% 
  filter(publication_year <=2024) %>% 
  ggplot(aes(x=publication_year, y=gap, 
             size = tot,
             color = continent))+
  geom_point(alpha= .7)+
  geom_smooth()+
  geom_hline(yintercept = 0, size = .2)+
  scale_size(range=c(1,8))+
  scale_y_continuous(labels = function(x) paste0(x*100,"%"))+
  scale_color_manual(values = region_colors)+
  theme_minimal()+
  theme(legend.text = element_text(size =12))+
  theme(strip.text.x = element_text(size =12))+
  theme(legend.position = "none")+
  guides(size = "none",
         color = guide_legend(ncol = 1))+
  facet_wrap(~continent,scales="free",
             ,ncol=5
             ,labeller = label_wrap_gen(width = 20))+
  labs(color = "",
       x = "year", y ="Average FWCI gap"
       ,title = "B"
  )

aggregate_plot/gaps + plot_layout(heights = c(.2,.8))

ggsave("results/fwci_gap_countries_wall.png",bg="white",height = 10,width = 12)


#############weighted reference bias###################

gendered_references <- read_csv("data/gendered_references_year_homophily_field.csv") %>% 
  mutate(country_code = countrycode(country,'country.name', 'iso2c')) %>% 
  mutate(country_code = case_when(
    country == "Kosovo" ~"XK",
    country == "Micronesia" ~"FM",
    TRUE ~country_code
  )) %>% 
  mutate(continent = countrycode(sourcevar = country_code,
                                 origin = "iso2c",
                                 destination = "un.regionsub.name")) %>% 
  mutate(continent = case_when(continent %in% c("Melanesia","Micronesia","Polynesia","Australia and New Zealand") ~"Oceania",
                               country_code == "TW" ~ "Eastern Asia",
                               country_code == "XK" ~ "Eastern Europe",
                               TRUE ~ continent))

gendered_references_weights <- read_csv("data/weights_references_norm.csv") %>% 
  mutate(country_code = countrycode(country,'country.name', 'iso2c')) %>% 
  mutate(country_code = case_when(
    country == "Kosovo" ~"XK",
    country == "Micronesia" ~"FM",
    TRUE ~country_code
  )) %>% 
  mutate(continent = countrycode(sourcevar = country_code,
                                 origin = "iso2c",
                                 destination = "un.regionsub.name")) %>% 
  mutate(continent = case_when(continent %in% c("Melanesia","Micronesia","Polynesia","Australia and New Zealand") ~"Oceania",
                               #continent %in% c("Central Asia","Eastern Asia")|country_code == "TW"  ~"North-eastern Asia",
                               country_code == "TW" ~ "Eastern Asia",
                               country_code == "XK" ~ "Eastern Europe",
                               TRUE ~ continent))


clean_gendered_references <- gendered_references %>% 
  filter(citing_field != "No data") %>% 
  group_by(continent,cited_gender,publication_year,citing_field) %>% 
  summarise(n_works = sum(n_works)) %>% 
  ungroup()


clean_gendered_references_weights <- gendered_references_weights %>% 
  filter(citing_field != "No data") %>% 
  group_by(continent,publication_year,citing_field) %>% 
  summarise(n_works = sum(n_works)) %>% 
  group_by(continent,publication_year) %>% 
  mutate(w = n_works/sum(n_works)) %>% 
  ungroup()

expected <- clean_gendered_references %>% 
  group_by(publication_year,citing_field,cited_gender) %>% 
  summarise(n = sum(n_works)) %>% 
  group_by(publication_year,citing_field) %>% 
  mutate(expected = n/sum(n)) %>% 
  ungroup() %>% select(-n)

weighted_expected_values <- clean_gendered_references_weights %>% 
  select(-n_works) %>% 
  left_join(expected, by = c("publication_year","citing_field")) %>% 
  group_by(continent,publication_year,cited_gender) %>% 
  summarise(exp = weighted.mean(x =expected, w = w))

observed <- clean_gendered_references %>% 
  group_by(continent,cited_gender,publication_year) %>%
  summarise(n_works = sum(n_works)) %>% 
  group_by(continent,publication_year) %>% 
  mutate(observed = n_works/sum(n_works))


full_table <- observed %>% 
  left_join(weighted_expected_values, by = c("publication_year","continent","cited_gender")) %>% 
  mutate(ratio = observed/exp,
         diff = observed - exp)

order <- full_table %>% 
  group_by(continent) %>% summarise(n = sum(n_works)) %>% 
  arrange(-n) %>% pull(continent)


full_table %>% 
  mutate(continent = factor(continent,levels = order)) %>% 
  mutate(gender_group = paste0("References to ",cited_gender )) %>% 
  filter(n_works > 100) %>% 
  filter(continent != "Central Asia") %>% 
  ggplot(aes(x = publication_year, y = diff
             ,size = n_works
             ,color = gender_group, fill = gender_group
  ))+
  geom_point(alpha = .7)+
  geom_smooth()+
  geom_hline(yintercept = 0, size = .2)+
  theme_minimal()+
  scale_color_manual(values = RColorBrewer::brewer.pal("Spectral", n = 11)[c(9,1)])+
  scale_fill_manual(values = RColorBrewer::brewer.pal("Spectral", n = 11)[c(9,1)])+
  scale_size(range=c(1,8))+
  #scale_y_continuous(limits = c(.8,1.25))+
  facet_wrap(~continent, scales = "free_x"
             ,ncol=5
             ,labeller = label_wrap_gen(width = 20))+
  theme(legend.position = c(.8,.2))+
  theme(legend.text = element_text(size =12))+
  theme(strip.text.x = element_text(size =12))+
  labs(y = "Difference between Observed and Expected proportion of references to women/men",
       x = "Publication year", color = "", fill = "")+
  guides(size = "none")+
  guides(fill = guide_legend(nrow = 2))+
  guides(color = guide_legend(nrow = 2))

ggsave("results/obs_exp_references_homo_together_diff.png",bg="white",height = 10,width = 12)

####supplementary - references######


full_table %>% 
  mutate(continent = factor(continent,levels = order)) %>% 
  mutate(gender_group = paste0("References to ",cited_gender )) %>% 
  filter(n_works > 100) %>% 
  filter(continent != "Central Asia") %>% 
  ggplot(aes(x = publication_year, y = observed
             ,size = n_works
             ,color = gender_group, fill = gender_group
  ))+
  geom_point(alpha = .7)+
  geom_smooth()+
  geom_hline(yintercept = 1, size = .2)+
  theme_minimal()+
  scale_color_manual(values = RColorBrewer::brewer.pal("Spectral", n = 11)[c(9,1)])+
  scale_fill_manual(values = RColorBrewer::brewer.pal("Spectral", n = 11)[c(9,1)])+
  scale_size(range=c(1,8))+
  #scale_y_continuous(limits = c(.8,1.25))+
  facet_wrap(~continent, scales = "free"
             ,ncol=5
             ,labeller = label_wrap_gen(width = 20))+
  theme(legend.position = c(.8,.2))+
  theme(legend.text = element_text(size =12))+
  theme(strip.text.x = element_text(size =12))+
  labs(y = "Observed proportion of references to women/men",
       x = "Publication year", color = "", fill = "")+
  guides(size = "none")+
  guides(fill = guide_legend(nrow = 2))+
  guides(color = guide_legend(nrow = 2))


ggsave("results/obs_exp_references_homo_together_check.png",bg="white",height = 10,width = 12)

####supplementary - map######

region_colors <- c(
  "Eastern Europe"                  = "#9467BD",
  "Latin America and the Caribbean" = "#E377C2",
  "Central Asia"                    = "#CD5B45",
  "Eastern Asia"                    = "#D62728",
  "Northern Africa"                 = "#BCBD22",
  "Northern America"                = "#4D4D4D",
  "Northern Europe"                 = "#AEC7E8",
  "Oceania"                         = "#4E9A51",
  "South-eastern Asia"              = "#B35400",
  "Southern Asia"                   = "#C97A2B",
  "Southern Europe"                 = "#1F77B4",
  "Sub-Saharan Africa"              = "#2CA02C",
  "Western Asia"                    = "#FFD92F",
  "Western Europe"                  = "#17BECF"
)

country_table <- read_excel("data/sql_results.xlsx", 
                            sheet = "country_frac_year") %>% 
  select(country) %>% unique() %>% 
  mutate(country_code = countrycode(country,'country.name', 'iso2c')) %>% 
  mutate(country_code = case_when(
    country == "Kosovo" ~"XK",
    country == "Micronesia" ~"FM",
    TRUE ~country_code
  )) %>% 
  mutate(continent = countrycode(sourcevar = country_code,
                                 origin = "iso2c",
                                 destination = "un.regionsub.name")) %>% 
  mutate(continent = case_when(continent %in% c("Melanesia","Micronesia","Polynesia","Australia and New Zealand") ~"Oceania",
                               country_code == "TW" ~ "Eastern Asia",
                               country_code == "XK" ~ "Eastern Europe",
                               TRUE ~ continent)) 



map <- ggplot2::map_data('world')%>%
  filter(region != "Antarctica") %>%
  mutate(iso2c = countrycode(region, 'country.name', 'iso2c')) %>%
  mutate(iso2c = case_when(region == "Kosovo" ~"XK",
                           region == "Micronesia" ~"FM",
                           region == "Western Sahara" ~ "MA",
                           TRUE ~ iso2c))


map %>%
  left_join(country_table, by = c("iso2c" = "country_code")) %>%
  filter(!is.na(continent)) %>% 
  ggplot(aes(x = long, y = lat, group = group, fill = continent)) +
  geom_polygon(color = "black", size = .2) +
  scale_fill_manual(values = region_colors, 
                    labels = function(x) str_wrap(x, 15)) +
  theme_void() +
  labs(title = "",
       fill = "Region",
       y = "", x = "") +
  coord_fixed(1.3) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme(legend.position = "bottom")+
  guides(fill = guide_legend(nrow = 4))

ggsave("results/supplementary_regions.png",bg="white",height = 6,width = 6)
