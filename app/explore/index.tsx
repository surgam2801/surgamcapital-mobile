import { useRouter } from "expo-router";
import { Text } from "react-native";
import { SiteShell } from "@/components/site/shell";
import { Card, Grid, IconTile, Section, styles as t } from "@/components/site/ui";
import { EXPLORE_TOOLS } from "@/shared/mf/content";

export default function Explore() {
  const router = useRouter();
  return (
    <SiteShell>
      <Section kicker="Explore" title="Research tools for mutual funds" subtitle="Compare funds, study categories and plan your goals and taxes.">
        <Grid min={260}>
          {EXPLORE_TOOLS.map((x, i) => (
            <Card key={x.slug} onPress={() => router.push(`/explore/${x.slug}` as never)} accessibilityLabel={x.title}>
              <IconTile icon={x.icon} tone={(["teal", "blue", "amber"] as const)[i % 3]} />
              <Text style={t.h3}>{x.title}</Text>
              <Text style={t.body}>{x.blurb}</Text>
            </Card>
          ))}
        </Grid>
      </Section>
    </SiteShell>
  );
}
