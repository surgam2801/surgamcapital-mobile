import { usePathname, useRouter } from "expo-router";
import { useState, type ReactNode } from "react";
import { Platform, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { SurgamMark } from "@/components/surgam/ui";
import { CALCULATORS, DISCLAIMER, EXPLORE_TOOLS, WAYS_TO_INVEST } from "@/shared/mf/content";
import { trpc } from "@/lib/trpc";
import { c, Container, Icon, useBreakpoint } from "./ui";

const NAV = [
  { label: "Home", href: "/" },
  { label: "Mutual Funds", href: "/mutual-funds" },
  { label: "Explore", href: "/explore" },
  { label: "Calculators", href: "/calculators" },
  { label: "About us", href: "/about" },
];

function isActive(pathname: string, href: string) {
  return href === "/" ? pathname === "/" : pathname.startsWith(href);
}

function AccountButton({ onNavigate }: { onNavigate?: () => void }) {
  const router = useRouter();
  const me = trpc.investor.me.useQuery(undefined, { retry: false, staleTime: 60_000 });
  const signedIn = !!me.data;
  return (
    <Pressable
      accessibilityRole="link"
      accessibilityLabel={signedIn ? "My account" : "Sign in"}
      onPress={() => {
        onNavigate?.();
        router.push((signedIn ? "/dashboard" : "/sign-in") as never);
      }}
      style={({ pressed }) => [s.account, pressed && { opacity: 0.8 }]}
    >
      <Icon name={signedIn ? "person-circle-outline" : "log-in-outline"} size={18} color={c.white} />
      <Text style={s.accountText}>{signedIn ? "My account" : "Sign in"}</Text>
    </Pressable>
  );
}

export function SiteHeader() {
  const router = useRouter();
  const pathname = usePathname();
  const { isDesktop } = useBreakpoint();
  const [open, setOpen] = useState(false);
  const go = (href: string) => {
    setOpen(false);
    router.push(href as never);
  };
  return (
    <View style={s.header}>
      <Container style={s.headerRow}>
        <Pressable accessibilityRole="link" accessibilityLabel="Surgam home" onPress={() => go("/")}>
          <SurgamMark />
        </Pressable>
        {isDesktop ? (
          <View style={s.nav} accessibilityRole="menubar">
            {NAV.map((n) => (
              <Pressable key={n.href} accessibilityRole="link" onPress={() => go(n.href)} style={[s.navItem, isActive(pathname, n.href) && s.navItemActive]}>
                <Text style={[s.navText, isActive(pathname, n.href) && s.navTextActive]}>{n.label}</Text>
              </Pressable>
            ))}
          </View>
        ) : null}
        <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
          <AccountButton onNavigate={() => setOpen(false)} />
          {!isDesktop ? (
            <Pressable accessibilityRole="button" accessibilityLabel={open ? "Close menu" : "Open menu"} onPress={() => setOpen(!open)} style={s.menuBtn}>
              <Icon name={open ? "close" : "menu"} size={24} color={c.ink} />
            </Pressable>
          ) : null}
        </View>
      </Container>
      {!isDesktop && open ? (
        <View style={s.drawer}>
          {NAV.map((n) => (
            <Pressable key={n.href} accessibilityRole="link" onPress={() => go(n.href)} style={[s.drawerItem, isActive(pathname, n.href) && { backgroundColor: c.mintSoft }]}>
              <Text style={[s.navText, { fontSize: 17 }, isActive(pathname, n.href) && s.navTextActive]}>{n.label}</Text>
              <Icon name="chevron-forward" size={18} color={c.muted} />
            </Pressable>
          ))}
        </View>
      ) : null}
    </View>
  );
}

function FooterCol({ title, links }: { title: string; links: { label: string; href?: string }[] }) {
  const router = useRouter();
  return (
    <View style={{ gap: 10, flexGrow: 1, flexBasis: 150 }}>
      <Text style={s.footHead}>{title}</Text>
      {links.map((l) =>
        l.href ? (
          <Pressable key={l.label} accessibilityRole="link" onPress={() => router.push(l.href as never)}>
            <Text style={s.footLink}>{l.label}</Text>
          </Pressable>
        ) : (
          <Text key={l.label} style={[s.footLink, { opacity: 0.7 }]}>{l.label}</Text>
        ),
      )}
    </View>
  );
}

export function SiteFooter() {
  const { isPhone } = useBreakpoint();
  return (
    <View style={s.footer}>
      <Container>
        <View style={s.footTop}>
          <View style={{ gap: 12, flexGrow: 1.4, flexBasis: isPhone ? "100%" : 220 }}>
            <View style={s.footBrand}>
              <SurgamMark />
            </View>
            <Text style={s.footBody}>A calmer way to understand and grow your long-term money plan.</Text>
          </View>
          <FooterCol title="Mutual Funds" links={[{ label: "Overview", href: "/mutual-funds" }, ...WAYS_TO_INVEST.map((w) => ({ label: w.title, href: `/mutual-funds/${w.slug}` }))]} />
          <FooterCol title="Explore" links={EXPLORE_TOOLS.map((t) => ({ label: t.title, href: `/explore/${t.slug}` }))} />
          <FooterCol title="Calculators" links={CALCULATORS.map((x) => ({ label: x.title, href: `/calculators/${x.slug}` }))} />
          <FooterCol title="Surgam" links={[{ label: "About us", href: "/about" }, { label: "FAQs", href: "/faqs" }, { label: "My account", href: "/dashboard" }, { label: "Contact details coming soon" }]} />
        </View>
        <View style={s.footRule} />
        <Text style={s.footSmall}>{DISCLAIMER}</Text>
        <Text style={s.footSmall}>Registration details (AMFI ARN and others) will be shown here once issued. Fund data: AMFI public NAV files.</Text>
        <Text style={[s.footSmall, { marginTop: 8 }]}>© {new Date().getFullYear()} Surgam Capital</Text>
      </Container>
    </View>
  );
}

export function SiteShell({ children }: { children: ReactNode }) {
  const insets = useSafeAreaInsets();
  return (
    <View style={{ flex: 1, backgroundColor: c.canvas, paddingTop: Platform.OS === "web" ? 0 : insets.top }}>
      <SiteHeader />
      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ flexGrow: 1 }} keyboardShouldPersistTaps="handled">
        <View style={{ flexGrow: 1 }}>{children}</View>
        <SiteFooter />
      </ScrollView>
    </View>
  );
}

const s = StyleSheet.create({
  header: { backgroundColor: c.surface, borderBottomWidth: 1, borderBottomColor: c.border, zIndex: 10 },
  headerRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", minHeight: 68, gap: 16 },
  nav: { flexDirection: "row", gap: 4, flex: 1, justifyContent: "center" },
  navItem: { paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12 },
  navItemActive: { backgroundColor: c.mintSoft },
  navText: { color: c.inkSoft, fontSize: 15, fontWeight: "700" },
  navTextActive: { color: c.evergreenDark },
  account: { flexDirection: "row", alignItems: "center", gap: 6, backgroundColor: c.evergreen, paddingHorizontal: 14, paddingVertical: 10, borderRadius: 12 },
  accountText: { color: c.white, fontSize: 14, fontWeight: "800" },
  menuBtn: { width: 44, height: 44, alignItems: "center", justifyContent: "center", borderRadius: 12 },
  drawer: { borderTopWidth: 1, borderTopColor: c.border, paddingVertical: 8, backgroundColor: c.surface },
  drawerItem: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingHorizontal: 20, paddingVertical: 14 },
  footer: { backgroundColor: c.ink, paddingVertical: 44 },
  footTop: { flexDirection: "row", flexWrap: "wrap", gap: 28 },
  footBrand: { alignSelf: "flex-start", backgroundColor: c.white, borderRadius: 14, paddingHorizontal: 12, paddingVertical: 8 },
  footBody: { color: "#C5D3D2", fontSize: 14, lineHeight: 21, maxWidth: 300 },
  footHead: { color: c.white, fontSize: 14, fontWeight: "800", marginBottom: 2 },
  footLink: { color: "#C5D3D2", fontSize: 14 },
  footRule: { height: 1, backgroundColor: "#2A3D3C", marginVertical: 24 },
  footSmall: { color: "#9FB1B0", fontSize: 12, lineHeight: 18 },
});
