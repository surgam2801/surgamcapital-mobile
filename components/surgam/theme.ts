import { Platform } from "react-native";

export const surgam = {
  colors: {
    // Greens shifted ~12° toward blue (2026-11 rebuild); other roles unchanged.
    ink: "#10201F",
    inkSoft: "#485F5E",
    muted: "#6D807F",
    canvas: "#F5F8F7",
    surface: "#FFFFFF",
    surfaceTint: "#EAF4F3",
    border: "#DCE6E5",
    evergreen: "#14787D",
    evergreenDark: "#0E5A5F",
    mint: "#BFE7E2",
    mintSoft: "#E8F5F3",
    blueSoft: "#E7F0FA",
    blue: "#2F6BA8",
    amberSoft: "#FFF3D6",
    amber: "#A66A00",
    coralSoft: "#FDE9E5",
    coral: "#B94B3F",
    white: "#FFFFFF",
  },
  radii: {
    card: 24,
    control: 16,
    pill: 999,
  },
  spacing: {
    xs: 6,
    sm: 10,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 44,
  },
  shadow: Platform.select({
    web: { boxShadow: "0px 10px 30px rgba(16, 33, 29, 0.06)" },
    default: {
      shadowColor: "#10201F",
      shadowOffset: { width: 0, height: 8 },
      shadowOpacity: 0.06,
      shadowRadius: 18,
      elevation: 3,
    },
  }),
};

export type SurgamIconName =
  | "home"
  | "investments"
  | "plans"
  | "help"
  | "plus"
  | "arrow-up"
  | "arrow-down"
  | "chevron"
  | "bell"
  | "check"
  | "phone"
  | "chat"
  | "document"
  | "calendar"
  | "close"
  | "shield"
  | "settings";
