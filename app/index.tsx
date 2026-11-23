import { StyleSheet, Text, View } from "react-native";
import { SiteShell } from "@/components/site/shell";
import { Button, c, Card, Container, Grid, Icon, IconTile, Section, styles as t, useBreakpoint } from "@/components/site/ui";
import { OFFERINGS } from "@/shared/mf/content";
import { CalculatorStrip, TopListsGrid, WaysToInvestGrid } from "@/components/site/sections";
import { trpc } from "@/lib/trpc";

function NumbersStrip() {
  const status = trpc.mf.status.useQuery(undefined, { retry: false, staleTime: 10 * 60_000 });
  const industry = trpc.mf.industry.useQuery(undefined, { retry: false, staleTime: 10 * 60_000 });
  const { isPhone } = useBreakpoint();
  const live = status.data?.source === "amfi";
  const items = [
    { value: live ? status.data!.schemes.toLocaleString("en-IN") : "1,500+", label: "funds you can research" },
    { value: industry.data && live ? String(industry.data.amcCount) : "40+", label: "fund houses covered" },
    { value: "₹500", label: "to start a monthly SIP" },
    { value: "0", label: "paperwork to begin" },
  ];
  return (
    <View style={[s.numbers, isPhone && { flexDirection: "column" }]}>
      {items.map((n) => (
        <View key={n.label} style={s.numberItem}>
          <Text style={s.numberValue}>{n.value}</Text>
          <Text style={s.numberLabel}>{n.label}</Text>
        </View>
      ))}
    </View>
  );
}

export default function Home() {
  const { isPhone, isDesktop } = useBreakpoint();
  return (
    <SiteShell>
      {/* Hero */}
      <View style={s.hero}>
        <Container style={[s.heroRow, !isDesktop && { flexDirection: "column", alignItems: "stretch" }]}>
          <View style={{ flex: 1.2, gap: 18 }}>
            <Text style={[t.kicker, { color: c.mint }]}>Surgam Capital</Text>
            <Text style={[t.h1, { color: c.white }, isPhone && { fontSize: 34, lineHeight: 41 }]} accessibilityRole="header">
              Grow your money with a plan you understand.
            </Text>
            <Text style={[t.lead, { color: "#D6E6E5" }]}>
              Surgam helps families pick mutual funds with calm, plain-language guidance. Set a goal, start a SIP and see exactly where you stand.
            </Text>
            <View style={{ flexDirection: "row", gap: 12, flexWrap: "wrap", marginTop: 6 }}>
              <Button label="Start investing" variant="light" icon="arrow-forward" size="lg" href="/sign-in" />
              <Button label="Explore mutual funds" variant="outlineLight" size="lg" href="/mutual-funds" />
            </View>
          </View>
          <View style={[s.heroCard, !isDesktop && { marginTop: 28 }]}>
            <Text style={s.heroCardKicker}>A SIP of ₹5,000 a month</Text>
            <Text style={s.heroCardValue}>could grow to about ₹25 lakh</Text>
            <Text style={s.heroCardBody}>over 15 years at an assumed 12% a year. Illustration only, not a promise of returns.</Text>
            <View style={s.heroBars}>
              {[18, 26, 34, 44, 58, 74, 92].map((h, i) => (
                <View key={i} style={[s.heroBar, { height: h }]} />
              ))}
            </View>
            <Button label="Try the SIP calculator" variant="secondary" icon="calculator-outline" href="/calculators/sip-wealth" />
          </View>
        </Container>
      </View>

      <Container style={{ marginTop: -36 }}>
        <NumbersStrip />
      </Container>

      <Section kicker="Mutual funds" title="Ways to invest" subtitle="Choose the style that fits you. You can mix more than one.">
        <WaysToInvestGrid />
      </Section>

      <Section tint kicker="Fund lists" title="Not sure where to start?" subtitle="Lists built from published fund data, refreshed every business day.">
        <TopListsGrid />
      </Section>

      <Section kicker="Why Surgam" title="Built for people who want clarity, not jargon">
        <Grid min={240}>
          {[
            { icon: "chatbubbles-outline", title: "Plain language", body: "Every screen explains what a number means and what you can do next." },
            { icon: "lock-closed-outline", title: "Your money stays yours", body: "Investments go straight to the fund house in your name. Surgam never holds your money." },
            { icon: "flag-outline", title: "Goal first", body: "Start from what you are saving for and let the plan work out the monthly amount." },
            { icon: "people-outline", title: "Help from real people", body: "Talk to a Surgam guide whenever you are unsure. No pressure, ever." },
          ].map((f) => (
            <View key={f.title} style={{ gap: 10 }}>
              <IconTile icon={f.icon} />
              <Text style={t.h4}>{f.title}</Text>
              <Text style={t.body}>{f.body}</Text>
            </View>
          ))}
        </Grid>
      </Section>

      <Section tint kicker="What you get" title="Everything for your mutual funds in one place">
        <Grid min={300}>
          {OFFERINGS.map((o) => (
            <Card key={o.title}>
              <View style={{ flexDirection: "row", gap: 12, alignItems: "center" }}>
                <IconTile icon={o.icon} tone="blue" />
                <Text style={t.h4}>{o.title}</Text>
              </View>
              <Text style={t.body}>{o.body}</Text>
            </Card>
          ))}
        </Grid>
      </Section>

      <Section kicker="Plan ahead" title="Goal planning calculators" subtitle="See the monthly amount each goal needs. No sign-in required." action={<Button label="All calculators" variant="secondary" href="/calculators" />}>
        <CalculatorStrip />
      </Section>

      <Section tint kicker="Learn" title="Investing basics" action={<Button label="Read the FAQs" variant="secondary" href="/faqs" />}>
        <Grid min={280}>
          {[
            { tag: "Guide", title: "SIP or lumpsum: which suits you?", body: "When a monthly SIP makes sense, and when a one-time amount can work better." },
            { tag: "Guide", title: "Equity, debt and hybrid in two minutes", body: "What each fund type does, and how long you should plan to stay invested." },
            { tag: "Guide", title: "How mutual fund gains are taxed", body: "Short-term and long-term gains, and the yearly tax-free limit." },
          ].map((a) => (
            <Card key={a.title}>
              <Text style={[t.kicker, { fontSize: 11 }]}>{a.tag}</Text>
              <Text style={t.h4}>{a.title}</Text>
              <Text style={t.body}>{a.body}</Text>
              <Text style={[t.small, { marginTop: "auto" }]}>Articles coming soon</Text>
            </Card>
          ))}
        </Grid>
      </Section>

      <View style={s.cta}>
        <Container style={[s.ctaRow, isPhone && { flexDirection: "column", alignItems: "flex-start" }]}>
          <View style={{ flex: 1, gap: 8 }}>
            <Text style={[t.h2, { color: c.white }, isPhone && { fontSize: 24 }]}>Invest on the web or the Surgam app</Text>
            <Text style={[t.body, { color: "#D6E6E5" }]}>Same account, same plans, on every screen. The app is coming to Android and iOS.</Text>
          </View>
          <Button label="Open your account" variant="light" icon="arrow-forward" size="lg" href="/sign-in" />
        </Container>
      </View>
    </SiteShell>
  );
}

const s = StyleSheet.create({
  hero: { backgroundColor: c.evergreenDark, paddingTop: 56, paddingBottom: 84 },
  heroRow: { flexDirection: "row", alignItems: "center", gap: 40 },
  heroCard: { flex: 0.9, backgroundColor: c.white, borderRadius: 24, padding: 24, gap: 10 },
  heroCardKicker: { color: c.inkSoft, fontSize: 14, fontWeight: "700" },
  heroCardValue: { color: c.ink, fontSize: 26, fontWeight: "900" },
  heroCardBody: { color: c.muted, fontSize: 13, lineHeight: 19 },
  heroBars: { flexDirection: "row", alignItems: "flex-end", gap: 10, height: 100, marginVertical: 8 },
  heroBar: { flex: 1, backgroundColor: c.mint, borderTopLeftRadius: 8, borderTopRightRadius: 8 },
  numbers: { flexDirection: "row", backgroundColor: c.surface, borderRadius: 20, borderWidth: 1, borderColor: c.border, padding: 8 },
  numberItem: { flex: 1, padding: 16, gap: 4 },
  numberValue: { color: c.evergreen, fontSize: 28, fontWeight: "900" },
  numberLabel: { color: c.inkSoft, fontSize: 13, fontWeight: "600" },
  more: { color: c.evergreen, fontWeight: "800", fontSize: 14, marginTop: "auto" },
  cta: { backgroundColor: c.evergreen, paddingVertical: 48 },
  ctaRow: { flexDirection: "row", alignItems: "center", gap: 24 },
});
