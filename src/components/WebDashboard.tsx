import React, { useState } from "react";
import {
  Car,
  User,
  Navigation,
  Flame,
  FileText,
  Shield,
  Activity,
  AlertTriangle,
  CheckCircle,
  Clock,
  Compass,
  MapPin,
  Settings,
  DollarSign,
  Plus,
  Search,
  Filter,
  Trash,
  Check,
  X,
  FileSpreadsheet,
  RotateCw,
  Sliders,
  AlertOctagon,
  Users,
  ShieldAlert,
  ClipboardList,
  Wrench,
  Boxes,
  Briefcase,
  Layers,
  ArrowRight,
  Sparkles
} from "lucide-react";
import {
  Vehicle,
  VehicleStatus,
  TrackerStatus,
  Driver,
  DriverStatus,
  Trip,
  TripStatus,
  Exception,
  ExceptionSeverity,
  FuelRequest,
  MaintenanceRequest,
  MaintenanceStatus,
  SparePart,
  Tyre,
  PolicyRule,
  Incident,
  AuditLog
} from "../types";
import FuelTheftDashboard from "./FuelTheftDashboard";

interface WebDashboardProps {
  vehicles: Vehicle[];
  drivers: Driver[];
  trips: Trip[];
  fuelRequests: FuelRequest[];
  maintenanceRequests: MaintenanceRequest[];
  exceptions: Exception[];
  incidents: Incident[];
  auditLogs: AuditLog[];
  policyRules: PolicyRule[];
  spareParts: SparePart[];
  tyres: Tyre[];
  activeRole: string;
  onUpdateVehicles: (v: Vehicle[]) => void;
  onUpdateTrips: (t: Trip[]) => void;
  onUpdateFuelRequests: (f: FuelRequest[]) => void;
  onUpdateMaintenanceRequests: (m: MaintenanceRequest[]) => void;
  onUpdateExceptions: (e: Exception[]) => void;
  onUpdateIncidents: (i: Incident[]) => void;
  onUpdatePolicyRules: (p: PolicyRule[]) => void;
  onUpdateSpareParts: (s: SparePart[]) => void;
  onAddAuditLog: (action: string, entityType: string, entityId: string, details: string) => void;
  onResetData: () => void;
}

export default function WebDashboard({
  vehicles,
  drivers,
  trips,
  fuelRequests,
  maintenanceRequests,
  exceptions,
  incidents,
  auditLogs,
  policyRules,
  spareParts,
  tyres,
  activeRole,
  onUpdateVehicles,
  onUpdateTrips,
  onUpdateFuelRequests,
  onUpdateMaintenanceRequests,
  onUpdateExceptions,
  onUpdateIncidents,
  onUpdatePolicyRules,
  onUpdateSpareParts,
  onAddAuditLog,
  onResetData
}: WebDashboardProps) {
  const [activeSidebar, setActiveSidebar] = useState<string>("overview");
  
  // Search & Filter state
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [severityFilter, setSeverityFilter] = useState<string>("All");
  
  // Details Drawers / Modals
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null);
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [selectedException, setSelectedException] = useState<Exception | null>(null);
  const [showAddPart, setShowAddPart] = useState<boolean>(false);
  
  // New part form
  const [newPart, setNewPart] = useState({
    partName: "",
    partNumber: "",
    category: "Filters",
    compatibleVehicleModel: "Toyota Prado",
    unitCost: 50,
    stockQty: 10,
    reorderLevel: 3
  });

  // Policy Rule Editor State
  const [editingRuleId, setEditingRuleId] = useState<string | null>(null);
  const [editingRuleValue, setEditingRuleValue] = useState<string>("");

  // Resolution Notes for Exception
  const [resolutionNotes, setResolutionNotes] = useState<string>("");

  // Counts & Totals
  const totalVehiclesCount = vehicles.length;
  const activeVehiclesCount = vehicles.filter(v => v.status === VehicleStatus.Active).length;
  const underMaintCount = vehicles.filter(v => v.status === VehicleStatus.UnderMaintenance).length;
  const criticalExceptionsCount = exceptions.filter(e => e.severity === ExceptionSeverity.Critical && e.status === "Open").length;
  
  const currentMonthFuelCost = fuelRequests
    .filter(f => f.status === "Completed")
    .reduce((sum, f) => sum + (f.actualCost || 0), 0);
    
  const currentMonthMaintCost = maintenanceRequests
    .filter(m => m.status === MaintenanceStatus.Completed || m.status === MaintenanceStatus.Verified)
    .reduce((sum, m) => sum + (m.invoiceAmount || m.quotationAmount || 0), 0);

  // Filtered lists
  const filteredExceptions = exceptions.filter(e => {
    const matchesSearch = e.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          e.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesSeverity = severityFilter === "All" || e.severity === severityFilter;
    return matchesSearch && matchesSeverity;
  });

  // Handle Approvals
  const handleApproveFuel = (id: string) => {
    const updated = fuelRequests.map(fr => fr.id === id ? { ...fr, status: "Approved" as const } : fr);
    onUpdateFuelRequests(updated);
    onAddAuditLog(activeRole, "FuelRequest", id, "Approved fuel card voucher dispatch.");
    alert("Fuel card voucher approved and dispatched to driver.");
  };

  const handleRejectFuel = (id: string) => {
    const updated = fuelRequests.map(fr => fr.id === id ? { ...fr, status: "Rejected" as const } : fr);
    onUpdateFuelRequests(updated);
    onAddAuditLog(activeRole, "FuelRequest", id, "Rejected fuel request claim.");
  };

  const handleApproveRepair = (id: string, cost: number) => {
    const updated = maintenanceRequests.map(mr => mr.id === id ? {
      ...mr,
      status: MaintenanceStatus.Approved,
      approvedAmount: cost
    } : mr);
    onUpdateMaintenanceRequests(updated);
    onAddAuditLog(activeRole, "MaintenanceRequest", id, `Approved repair work-order quotation of $${cost}`);
    alert("Repair work-order approved. Garage notified.");
  };

  // Handle Exception Resolution
  const handleResolveException = (id: string) => {
    if (!resolutionNotes.trim()) {
      alert("Please provide official investigation findings and resolution notes before closure.");
      return;
    }
    const updated = exceptions.map(exc => exc.id === id ? {
      ...exc,
      status: "Resolved" as const,
      resolutionNotes,
      resolvedBy: activeRole
    } : exc);
    onUpdateExceptions(updated);
    onAddAuditLog(activeRole, "Exception", id, `Resolved anomaly flag. Resolution: ${resolutionNotes}`);
    setSelectedException(null);
    setResolutionNotes("");
    alert("Anomaly file closed. Audit log sealed.");
  };

  // Handle policy edit
  const handleSavePolicyRule = (ruleId: string) => {
    const updated = policyRules.map(r => r.id === ruleId ? { ...r, value: editingRuleValue } : r);
    onUpdatePolicyRules(updated);
    onAddAuditLog(activeRole, "PolicyRule", ruleId, `Modified policy limit/value to ${editingRuleValue}`);
    setEditingRuleId(null);
    alert("Enterprise policy updated. System thresholds recalibrated.");
  };

  // Handle Add Spare Part
  const handleAddSparePartSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newId = "s-" + Math.random().toString(36).substr(2, 9);
    const part: SparePart = {
      id: newId,
      ...newPart
    };
    onUpdateSpareParts([part, ...spareParts]);
    onAddAuditLog(activeRole, "SparePart", newId, `Added new part catalogue record: ${newPart.partName}`);
    setShowAddPart(false);
    setNewPart({
      partName: "",
      partNumber: "",
      category: "Filters",
      compatibleVehicleModel: "Toyota Prado",
      unitCost: 50,
      stockQty: 10,
      reorderLevel: 3
    });
    alert("Stock ledger updated successfully.");
  };

  // AI Predictive Maintenance Simulation Handlers
  const handleSimulateMileageAccumulation = () => {
    const updated = vehicles.map(v => {
      const increment = v.status === VehicleStatus.Grounded ? 0 : 1500;
      return {
        ...v,
        currentOdometer: v.currentOdometer + increment
      };
    });
    onUpdateVehicles(updated);
    onAddAuditLog(
      activeRole, 
      "Vehicle", 
      "ALL", 
      "Simulated fleet-wide high utilization: increased active vehicle odometers by +1,500 KM to test wear alerts."
    );
    alert("Fleet odometer logs increased by 1,500 KM! AI Predictive wear models recalibrated.");
  };

  const handlePerformService = (vehicleId: string, partCategory: "Oil" | "Brakes" | "Filters" | "Full") => {
    const v = vehicles.find(veh => veh.id === vehicleId);
    if (!v) return;

    const newId = "m-auto-" + Math.random().toString(36).substr(2, 9);
    let desc = "";
    let parts: any[] = [];
    let cost = 0;

    if (partCategory === "Oil") {
      desc = "AI Predictive Service Dispatch: Preventative Engine Oil & Filter Service performed.";
      parts = [
        { partName: "Premium Synthetic Engine Oil (5L)", partNumber: "TOY-OIL-SYN5", cost: 120, serialInstalled: "OIL-" + Math.floor(10000 + Math.random() * 90000) },
        { partName: "Toyota OEM Oil Filter", partNumber: "TOY-FIL-092", cost: 30, serialInstalled: "FIL-" + Math.floor(10000 + Math.random() * 90000) }
      ];
      cost = 150;
    } else if (partCategory === "Brakes") {
      desc = "AI Predictive Service Dispatch: Preventative Brake system overhaul and pad replacement.";
      parts = [
        { partName: "Heavy Duty Front Brake Pads (Set)", partNumber: "PAD-FR-HD880", cost: 85, serialInstalled: "BRK-" + Math.floor(10000 + Math.random() * 90000) }
      ];
      cost = 180;
    } else if (partCategory === "Filters") {
      desc = "AI Predictive Service Dispatch: Scheduled air filter and cabin element swap.";
      parts = [
        { partName: "Premium Air Filter element", partNumber: "TOY-FIL-AIR", cost: 45, serialInstalled: "AIR-" + Math.floor(10000 + Math.random() * 90000) }
      ];
      cost = 45;
    } else {
      desc = "AI Predictive Service Dispatch: 360° Comprehensive Routine Maintenance and Wear Overhaul.";
      parts = [
        { partName: "Premium Synthetic Engine Oil (5L)", cost: 120, serialInstalled: "OIL-" + Math.floor(10000 + Math.random() * 90000) },
        { partName: "Toyota OEM Oil Filter", cost: 30, serialInstalled: "FIL-" + Math.floor(10000 + Math.random() * 90000) },
        { partName: "Heavy Duty Front Brake Pads (Set)", cost: 85, serialInstalled: "BRK-" + Math.floor(10000 + Math.random() * 90000) },
        { partName: "Premium Air Filter element", cost: 45, serialInstalled: "AIR-" + Math.floor(10000 + Math.random() * 90000) }
      ];
      cost = 280;
    }

    const newRequest: MaintenanceRequest = {
      id: newId,
      vehicleId: v.id,
      driverId: v.assignedDriverId || "d1",
      category: "Routine",
      description: desc,
      severity: "Low",
      odometer: v.currentOdometer,
      timestamp: new Date().toISOString(),
      status: MaintenanceStatus.Verified, // Directly completed and verified!
      garageName: "Official Authorized Fleet Garage",
      quotationAmount: cost,
      approvedAmount: cost,
      invoiceAmount: cost,
      completionNotes: `Preventative servicing performed. All wear meters reset to 0 KM.`,
      partsReplaced: parts,
      testDrivePassed: true
    };

    // If vehicle was Under Maintenance, make it Active again
    if (v.status === VehicleStatus.UnderMaintenance) {
      const updatedVehicles = vehicles.map(veh => veh.id === v.id ? { ...veh, status: VehicleStatus.Active } : veh);
      onUpdateVehicles(updatedVehicles);
    }

    onUpdateMaintenanceRequests([newRequest, ...maintenanceRequests]);
    onAddAuditLog(activeRole, "MaintenanceRequest", newId, `Executed AI-triggered preventative service (${partCategory}) for vehicle ${v.registrationNumber}.`);
    alert(`Preventative Service (${partCategory}) executed successfully for vehicle ${v.registrationNumber}! Service wear odometer has been reset.`);
  };

  return (
    <div className="flex-1 flex overflow-hidden min-h-0 bg-neutral-900 border border-neutral-800 rounded-3xl shadow-xl">
      
      {/* Sidebar Navigation */}
      <aside className="w-56 bg-neutral-950 border-r border-neutral-800 flex flex-col justify-between p-4 font-sans shrink-0">
        <div className="space-y-6">
          <div className="px-2 py-1 flex items-center space-x-2">
            <div className="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center text-amber-500">
              <Shield className="w-4 h-4" />
            </div>
            <div>
              <span className="text-white text-xs font-black tracking-wider">FLEET SHIELD</span>
              <p className="text-[9px] text-neutral-400 font-mono">Anti-Fraud & Audit</p>
            </div>
          </div>

          <nav className="space-y-1">
            <button
              onClick={() => setActiveSidebar("overview")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "overview" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Activity className="w-4 h-4" />
              <span>Overview</span>
            </button>

            <button
              onClick={() => setActiveSidebar("live-map")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "live-map" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Compass className="w-4 h-4" />
              <span>Live tracking</span>
            </button>

            <button
              onClick={() => setActiveSidebar("exceptions")}
              className={`w-full flex justify-between items-center px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "exceptions" ? "bg-rose-500 text-white" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <span className="flex items-center space-x-2.5">
                <AlertTriangle className="w-4 h-4" />
                <span>Exceptions</span>
              </span>
              {exceptions.filter(e => e.status === "Open").length > 0 && (
                <span className="bg-rose-900 text-white text-[9px] px-1.5 py-0.5 rounded font-mono font-black animate-pulse">
                  {exceptions.filter(e => e.status === "Open").length}
                </span>
              )}
            </button>

            <button
              onClick={() => setActiveSidebar("trips")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "trips" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Navigation className="w-4 h-4" />
              <span>Trip movement</span>
            </button>

            <button
              onClick={() => setActiveSidebar("vehicles")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "vehicles" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Car className="w-4 h-4" />
              <span>Vehicle registry</span>
            </button>

            <button
              onClick={() => setActiveSidebar("drivers")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "drivers" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <User className="w-4 h-4" />
              <span>Driver profiles</span>
            </button>

            <button
              onClick={() => setActiveSidebar("fuel")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "fuel" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Flame className="w-4 h-4" />
              <span>Fuel audit</span>
            </button>

            <button
              onClick={() => setActiveSidebar("maintenance")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "maintenance" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Wrench className="w-4 h-4" />
              <span>Maintenance</span>
            </button>

            <button
              onClick={() => setActiveSidebar("maintenance-forecast")}
              className={`w-full flex justify-between items-center px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "maintenance-forecast" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <span className="flex items-center space-x-2.5">
                <Sparkles className="w-4 h-4 text-amber-500" />
                <span>Service Forecast</span>
              </span>
              <span className="bg-amber-500/10 text-amber-400 text-[9px] px-1.5 py-0.5 rounded font-mono font-bold uppercase shrink-0">
                AI Predict
              </span>
            </button>

            <button
              onClick={() => setActiveSidebar("inventory")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "inventory" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Boxes className="w-4 h-4" />
              <span>Spare parts catalog</span>
            </button>

            <button
              onClick={() => setActiveSidebar("policy")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "policy" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <Sliders className="w-4 h-4" />
              <span>Policy engine</span>
            </button>

            <button
              onClick={() => setActiveSidebar("approvals")}
              className={`w-full flex justify-between items-center px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "approvals" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <span className="flex items-center space-x-2.5">
                <CheckCircle className="w-4 h-4" />
                <span>Approvals</span>
              </span>
              {fuelRequests.filter(f => f.status === "Pending").length + maintenanceRequests.filter(m => m.status === MaintenanceStatus.Pending).length > 0 && (
                <span className="bg-amber-500/10 text-amber-500 text-[10px] px-1.5 py-0.2 rounded font-mono">
                  {fuelRequests.filter(f => f.status === "Pending").length + maintenanceRequests.filter(m => m.status === MaintenanceStatus.Pending).length}
                </span>
              )}
            </button>

            <button
              onClick={() => setActiveSidebar("audit-trail")}
              className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition ${
                activeSidebar === "audit-trail" ? "bg-amber-500 text-neutral-950" : "text-neutral-400 hover:bg-neutral-900 hover:text-white"
              }`}
            >
              <ShieldAlert className="w-4 h-4" />
              <span>Blackbox trail</span>
            </button>
          </nav>
        </div>

        {/* Sidebar Footer */}
        <div className="pt-4 border-t border-neutral-800 text-center space-y-2">
          <div className="bg-neutral-900 p-2 rounded-lg text-[10px] font-mono text-neutral-400">
            Role: <span className="text-white font-extrabold capitalize">{activeRole}</span>
          </div>
          <button
            onClick={onResetData}
            className="w-full text-[10px] py-1 bg-rose-950 hover:bg-rose-900 text-rose-300 font-bold rounded-lg border border-rose-900/30 transition flex items-center justify-center space-x-1"
            title="Reset system to pre-populated demo database"
          >
            <RotateCw className="w-3 h-3" />
            <span>Reset Database</span>
          </button>
        </div>
      </aside>

      {/* Main Panel Content */}
      <main className="flex-1 bg-neutral-950 flex flex-col min-h-0 overflow-y-auto">
        
        {/* Top Header Bar */}
        <header className="h-14 border-b border-neutral-900 flex justify-between items-center px-6 shrink-0 bg-neutral-950/80 backdrop-blur z-20">
          <div>
            <h2 className="text-sm font-extrabold text-white flex items-center space-x-2 uppercase tracking-wide">
              <span>{activeSidebar.replace("-", " ")}</span>
            </h2>
            <p className="text-[10px] text-neutral-500 font-mono">UTC: 2026-07-11 03:55 AM | Operator: mohamedamadubangura@gmail.com</p>
          </div>
          
          <div className="flex items-center space-x-3">
            {/* Action Indicators */}
            <div className="flex items-center space-x-1 bg-rose-500/10 text-rose-400 border border-rose-500/20 px-2 py-1 rounded text-[10px] font-bold font-mono">
              <AlertTriangle className="w-3.5 h-3.5 animate-pulse" />
              <span>{exceptions.filter(e => e.status === "Open").length} UNRESOLVED ANOMALIES</span>
            </div>
          </div>
        </header>

        {/* Content Panel Swapping */}
        <div className="p-6 flex-1 min-h-0">
          
          {/* OVERVIEW MODULE */}
          {activeSidebar === "overview" && (
            <div className="space-y-6">
              {/* Grid of high-integrity KPI summary cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                  <div>
                    <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider">ACTIVE SHUTTLE TRIPS</span>
                    <h3 className="text-2xl font-black mt-1 text-white">{activeVehiclesCount} <span className="text-xs text-neutral-500 font-normal">in progress</span></h3>
                    <p className="text-[10px] text-emerald-400 font-mono mt-1">✓ Live GPS streaming</p>
                  </div>
                  <div className="bg-emerald-500/10 text-emerald-400 p-2.5 rounded-lg">
                    <Navigation className="w-5 h-5" />
                  </div>
                </div>

                <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                  <div>
                    <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider">FUEL SPEND (MONTH)</span>
                    <h3 className="text-2xl font-black mt-1 text-white">${currentMonthFuelCost}</h3>
                    <p className="text-[10px] text-rose-400 font-mono mt-1">⚠ {exceptions.filter(e => e.type === "Fuel").length} fuel variance warnings</p>
                  </div>
                  <div className="bg-amber-500/10 text-amber-500 p-2.5 rounded-lg">
                    <Flame className="w-5 h-5" />
                  </div>
                </div>

                <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                  <div>
                    <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider">MAINTENANCE BILLS</span>
                    <h3 className="text-2xl font-black mt-1 text-white">${currentMonthMaintCost}</h3>
                    <p className="text-[10px] text-neutral-400 font-mono mt-1">{underMaintCount} vehicles currently in bay</p>
                  </div>
                  <div className="bg-blue-500/10 text-blue-400 p-2.5 rounded-lg">
                    <Wrench className="w-5 h-5" />
                  </div>
                </div>

                <div className="bg-neutral-900 p-4 rounded-xl border border-rose-500/20 flex justify-between items-start">
                  <div>
                    <span className="text-[10px] text-rose-400 font-bold uppercase tracking-wider">CRITICAL ANOMALIES</span>
                    <h3 className="text-2xl font-black mt-1 text-rose-500">{criticalExceptionsCount}</h3>
                    <p className="text-[10px] text-rose-400 font-mono mt-1">!!! High risk of siphoning</p>
                  </div>
                  <div className="bg-rose-500/10 text-rose-400 p-2.5 rounded-lg animate-bounce">
                    <AlertOctagon className="w-5 h-5" />
                  </div>
                </div>
              </div>

              {/* AI Predictive Maintenance Alert Center */}
              {(() => {
                const warnCount = vehicles.filter(v => {
                  const completedMaint = maintenanceRequests.filter(m => m.vehicleId === v.id && (m.status === MaintenanceStatus.Completed || m.status === MaintenanceStatus.Verified));
                  const lastOilOdo = completedMaint.reduce((max, m) => {
                    const hasOil = m.description.toLowerCase().includes("oil") || m.partsReplaced?.some(p => p.partName.toLowerCase().includes("oil"));
                    return (hasOil && m.odometer > max) ? m.odometer : max;
                  }, Math.max(0, v.currentOdometer - 2200));
                  
                  const lastBrakesOdo = completedMaint.reduce((max, m) => {
                    const hasBrakes = m.description.toLowerCase().includes("brake") || m.partsReplaced?.some(p => p.partName.toLowerCase().includes("brake"));
                    return (hasBrakes && m.odometer > max) ? m.odometer : max;
                  }, Math.max(0, v.currentOdometer - 13200));

                  const isOilOverdue = (v.currentOdometer - lastOilOdo) >= 5000;
                  const isBrakesOverdue = v.id === "v3" || (v.currentOdometer - lastBrakesOdo) >= 15000; // v3 is forced overdue due to active complaint
                  return (isOilOverdue || isBrakesOverdue) && v.status !== VehicleStatus.Grounded;
                }).length;

                if (warnCount === 0) return null;

                return (
                  <div className="bg-amber-500/10 border border-amber-500/25 rounded-2xl p-4 flex flex-col md:flex-row justify-between items-start md:items-center space-y-3 md:space-y-0 shadow-lg">
                    <div className="space-y-1">
                      <div className="flex items-center space-x-2 text-amber-400 font-extrabold text-xs">
                        <Sparkles className="w-5 h-5 text-amber-500 animate-pulse" />
                        <span className="uppercase tracking-widest font-black">AI PREDICTIVE SERVICE DISPATCH ALERT</span>
                      </div>
                      <p className="text-xs text-neutral-300">
                        Wear model indicates <span className="text-amber-400 font-bold">{warnCount} vehicles</span> are operating with critical component wear (engine oil dilution or overdue brake pads). Schedule preventative maintenance now.
                      </p>
                    </div>
                    <button
                      onClick={() => setActiveSidebar("maintenance-forecast")}
                      className="bg-amber-500 hover:bg-amber-600 text-neutral-950 text-xs px-4 py-2 rounded-xl font-bold flex items-center space-x-1.5 shrink-0 transition"
                    >
                      <span>Analyze Forecast</span>
                      <ArrowRight className="w-4 h-4 text-neutral-950" />
                    </button>
                  </div>
                );
              })()}

              {/* Exception Alert Command Center Row */}
              <div className="bg-rose-950/20 border border-rose-500/20 rounded-2xl p-4 flex flex-col md:flex-row justify-between items-start md:items-center space-y-3 md:space-y-0">
                <div className="space-y-1">
                  <div className="flex items-center space-x-2 text-rose-400">
                    <ShieldAlert className="w-5 h-5 text-rose-500" />
                    <span className="text-xs font-extrabold uppercase tracking-widest">CRITICAL EXCEPTION CENTER</span>
                  </div>
                  <p className="text-xs text-neutral-400">
                    Odometer spoofing, unapproved garage repair claims, and fuel variance outliers are highlighted instantly below.
                  </p>
                </div>
                <button
                  onClick={() => setActiveSidebar("exceptions")}
                  className="bg-rose-600 hover:bg-rose-700 text-white text-xs px-4 py-2 rounded-xl font-bold flex items-center space-x-1 shrink-0"
                >
                  <span>Investigate Active Exceptions</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>

              {/* Grid: Map and Drivers */}
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                
                {/* Visual Freetown Map Simulator */}
                <div className="lg:col-span-2 bg-neutral-900 border border-neutral-800 rounded-2xl p-4 flex flex-col h-[320px]">
                  <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider mb-2">Live Map (Freetown Hub Telemetry)</h3>
                  
                  {/* Styled Map Container */}
                  <div className="flex-1 bg-neutral-950 rounded-xl relative overflow-hidden border border-neutral-800 flex items-center justify-center">
                    {/* SVG Map Lines Simulation */}
                    <svg className="absolute inset-0 w-full h-full opacity-10 pointer-events-none">
                      <path d="M 10 50 Q 80 150 150 120 T 300 200" fill="none" stroke="white" strokeWidth="2" />
                      <path d="M 50 10 L 250 180" fill="none" stroke="white" strokeWidth="1.5" />
                      <path d="M 0 100 H 400" fill="none" stroke="white" strokeWidth="1" />
                    </svg>

                    {/* Geofences & Points */}
                    <div className="absolute top-10 left-10 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[8px] font-mono px-1.5 py-0.5 rounded">
                      GEOFENCE: CENTRAL DEPOT
                    </div>
                    <div className="absolute bottom-16 right-10 bg-rose-500/10 border border-rose-500/20 text-rose-400 text-[8px] font-mono px-1.5 py-0.5 rounded">
                      GEOFENCE: BLACKLISTED GARAGE
                    </div>

                    {/* Plot Vehicles */}
                    {vehicles.map(v => (
                      <div
                        key={v.id}
                        onClick={() => setSelectedVehicle(v)}
                        className={`absolute cursor-pointer p-1.5 rounded-lg border flex items-center space-x-1.5 shadow-lg active:scale-95 transition ${
                          v.id === "v1" ? "top-1/3 left-1/4 bg-emerald-950 border-emerald-500 text-emerald-400" :
                          v.id === "v2" ? "top-1/2 left-1/2 bg-neutral-900 border-neutral-700 text-neutral-400" :
                          v.id === "v3" ? "bottom-1/4 right-1/4 bg-rose-950 border-rose-500 text-rose-400 animate-pulse" :
                          "top-1/4 right-1/3 bg-blue-950 border-blue-500 text-blue-400"
                        }`}
                      >
                        <MapPin className="w-3 h-3" />
                        <span className="text-[10px] font-mono font-bold">{v.registrationNumber}</span>
                        {v.id === "v3" && <AlertTriangle className="w-2.5 h-2.5 text-rose-400" />}
                      </div>
                    ))}
                    
                    <span className="absolute bottom-2 left-2 text-[8px] text-neutral-600 font-mono">
                      Interact with maps: click pins to view vehicle health.
                    </span>
                  </div>
                </div>

                {/* Driver Risk Rankings */}
                <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-4 flex flex-col h-[320px]">
                  <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider mb-3">Driver Accountability Ratings</h3>
                  
                  <div className="flex-1 overflow-y-auto space-y-2">
                    {drivers.map(drv => (
                      <div key={drv.id} className="bg-neutral-950 p-2.5 rounded-xl border border-neutral-800 flex items-center justify-between">
                        <div className="flex items-center space-x-2.5">
                          <img src={drv.photoUrl} alt={drv.name} className="w-8 h-8 rounded-full object-cover border border-neutral-800" />
                          <div>
                            <h4 className="text-xs font-bold text-white">{drv.name}</h4>
                            <p className="text-[9px] text-neutral-500 font-mono">Compliance Score: {drv.performanceScore}%</p>
                          </div>
                        </div>

                        <div className="text-right">
                          <span className={`text-[10px] px-2 py-0.5 rounded font-mono font-bold ${
                            drv.riskScore > 50 ? "bg-rose-500/10 text-rose-400" : "bg-emerald-500/10 text-emerald-400"
                          }`}>
                            Risk Index: {drv.riskScore}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                  <p className="text-[9px] text-neutral-500 mt-2 italic font-mono text-center">
                    Risk score inputs: fuel variance count, late return logs, offline time.
                  </p>
                </div>

              </div>

            </div>
          )}

          {/* EXCEPTIONS MODULE (CRITICAL COMMAND CENTER) */}
          {activeSidebar === "exceptions" && (
            <div className="space-y-4">
              <div className="flex justify-between items-center mb-1">
                <div className="flex items-center space-x-2">
                  <ShieldAlert className="w-5 h-5 text-rose-500" />
                  <p className="text-xs text-neutral-400">Manage, investigate, and close fuel variance or vehicle tampering exceptions.</p>
                </div>
                
                {/* Simple Filters */}
                <div className="flex items-center space-x-2">
                  <Search className="w-4 h-4 text-neutral-400" />
                  <input
                    type="text"
                    placeholder="Search exceptions..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="bg-neutral-900 border border-neutral-800 text-xs text-white rounded-lg p-1.5 focus:outline-none focus:ring-1 focus:ring-amber-500"
                  />
                  <select
                    value={severityFilter}
                    onChange={(e) => setSeverityFilter(e.target.value)}
                    className="bg-neutral-900 border border-neutral-800 text-xs text-white rounded-lg p-1.5 font-mono"
                  >
                    <option value="All">All Severities</option>
                    <option value="Low">Low</option>
                    <option value="Medium">Medium</option>
                    <option value="High">High</option>
                    <option value="Critical">Critical</option>
                  </select>
                </div>
              </div>

              <div className="space-y-3">
                {filteredExceptions.map(exc => (
                  <div
                    key={exc.id}
                    className={`p-4 rounded-xl border flex flex-col justify-between transition hover:border-neutral-700 ${
                      exc.status === "Resolved" ? "bg-neutral-900/40 border-neutral-800/80" :
                      exc.severity === ExceptionSeverity.Critical ? "bg-rose-950/20 border-rose-500/30" : "bg-neutral-900 border-neutral-800"
                    }`}
                  >
                    <div className="flex justify-between items-start">
                      <div className="space-y-1.5">
                        <div className="flex items-center space-x-2">
                          <span className={`text-[9px] px-2 py-0.5 rounded-full font-black font-mono ${
                            exc.severity === ExceptionSeverity.Critical ? "bg-rose-500 text-neutral-950" :
                            exc.severity === ExceptionSeverity.High ? "bg-amber-500 text-neutral-950" : "bg-neutral-800 text-neutral-400"
                          }`}>
                            {exc.severity} severity
                          </span>
                          <span className="text-[10px] text-neutral-400 font-mono">{new Date(exc.timestamp).toLocaleTimeString()}</span>
                          <span className={`text-[10px] font-mono px-1.5 py-0.2 rounded ${
                            exc.status === "Resolved" ? "bg-emerald-500/10 text-emerald-400" : "bg-rose-500/10 text-rose-400 animate-pulse"
                          }`}>
                            {exc.status}
                          </span>
                        </div>
                        <h4 className="text-xs font-black text-white">{exc.title}</h4>
                        <p className="text-xs text-neutral-300 max-w-4xl">{exc.description}</p>
                      </div>

                      {exc.status !== "Resolved" && (
                        <button
                          onClick={() => setSelectedException(exc)}
                          className="bg-neutral-950 hover:bg-neutral-900 border border-neutral-800 text-xs px-3 py-1.5 rounded-lg text-white font-bold tracking-wider"
                        >
                          Investigate
                        </button>
                      )}
                    </div>

                    {exc.status === "Resolved" && (
                      <div className="mt-3 pt-3 border-t border-neutral-800/60 text-xs text-neutral-400 flex items-start space-x-2">
                        <CheckCircle className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                        <div>
                          <strong>Investigation findings:</strong> {exc.resolutionNotes}
                          <p className="text-[10px] text-neutral-500 font-mono mt-0.5">Resolved by: {exc.resolvedBy}</p>
                        </div>
                      </div>
                    )}
                  </div>
                ))}

                {filteredExceptions.length === 0 && (
                  <div className="text-center py-12 text-neutral-500">
                    <CheckCircle className="w-10 h-10 text-neutral-600 mx-auto mb-2" />
                    <p className="text-xs font-bold">Excellent: No active accountability flags detected.</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* LIVE TRACKING MAP */}
          {activeSidebar === "live-map" && (
            <div className="space-y-4">
              <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-4 flex flex-col lg:flex-row gap-6">
                
                {/* Left Side: Map Visual */}
                <div className="flex-1 bg-neutral-950 rounded-xl h-[450px] relative border border-neutral-800 flex items-center justify-center overflow-hidden">
                  <svg className="absolute inset-0 w-full h-full opacity-10 pointer-events-none">
                    <path d="M 50 150 Q 180 250 250 220 T 400 300" fill="none" stroke="white" strokeWidth="2" />
                    <path d="M 120 50 L 350 380" fill="none" stroke="white" strokeWidth="1.5" />
                  </svg>

                  <div className="absolute top-10 left-10 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[10px] px-2 py-1 rounded font-mono">
                    GEOFENCE: FREETOWN CENTRAL DEPOT
                  </div>
                  <div className="absolute bottom-16 right-10 bg-rose-500/10 border border-rose-500/20 text-rose-400 text-[10px] px-2 py-1 rounded font-mono">
                    GEOFENCE: MECHANICAL HUB (RESTRICTED ZONE)
                  </div>

                  {/* Vehicle Markers */}
                  {vehicles.map(v => (
                    <div
                      key={v.id}
                      onClick={() => setSelectedVehicle(v)}
                      className={`absolute cursor-pointer p-2 rounded-xl border flex items-center space-x-2 shadow-2xl transition transform hover:scale-105 ${
                        v.id === "v1" ? "top-1/3 left-1/3 bg-emerald-950 border-emerald-500 text-emerald-400" :
                        v.id === "v2" ? "top-1/2 left-1/2 bg-neutral-900 border-neutral-700 text-neutral-400" :
                        v.id === "v3" ? "bottom-1/3 right-1/4 bg-rose-950 border-rose-500 text-rose-400 animate-pulse" :
                        "top-1/4 right-1/3 bg-blue-950 border-blue-500 text-blue-400"
                      }`}
                    >
                      <MapPin className="w-4 h-4" />
                      <div>
                        <p className="text-[10px] font-mono font-black">{v.registrationNumber}</p>
                        <p className="text-[8px] opacity-75">Odo: {v.currentOdometer.toLocaleString()}</p>
                      </div>
                    </div>
                  ))}
                  
                  <div className="absolute bottom-4 right-4 bg-neutral-900/90 border border-neutral-800 p-3 rounded-lg text-[10px] space-y-1.5 text-neutral-400 max-w-xs font-mono">
                    <p className="font-bold text-white uppercase mb-1">GEOFENCING LEGEND</p>
                    <div className="flex items-center space-x-1.5">
                      <span className="w-2.5 h-2.5 bg-emerald-500 rounded-full"></span>
                      <span>Approved Zone</span>
                    </div>
                    <div className="flex items-center space-x-1.5">
                      <span className="w-2.5 h-2.5 bg-rose-500 rounded-full animate-ping"></span>
                      <span>Restricted Garage Zone</span>
                    </div>
                  </div>
                </div>

                {/* Right Side: Map Controls & Details */}
                <div className="w-full lg:w-80 space-y-4">
                  <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider">Live Fleet Telemetry</h3>
                  <div className="space-y-2 max-h-[400px] overflow-y-auto">
                    {vehicles.map(v => (
                      <div
                        key={v.id}
                        onClick={() => setSelectedVehicle(v)}
                        className={`p-3 rounded-xl border cursor-pointer hover:bg-neutral-800/50 transition ${
                          selectedVehicle?.id === v.id ? "bg-neutral-800 border-amber-500" : "bg-neutral-950 border-neutral-800"
                        }`}
                      >
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-xs font-extrabold text-white">{v.registrationNumber}</span>
                          <span className={`text-[9px] px-1.5 py-0.2 rounded font-mono ${
                            v.status === VehicleStatus.Active ? "bg-emerald-500/20 text-emerald-400" : "bg-neutral-800 text-neutral-400"
                          }`}>
                            {v.status}
                          </span>
                        </div>
                        <p className="text-[11px] text-neutral-400">{v.make} {v.model}</p>
                        <div className="flex justify-between items-center mt-2 pt-2 border-t border-neutral-900 text-[10px] text-neutral-500 font-mono">
                          <span>Tracker: {v.trackerStatus}</span>
                          <span>Last seen: 3m ago</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

              </div>
            </div>
          )}

          {/* TRIPS MOVEMENT LOG */}
          {activeSidebar === "trips" && (
            <div className="space-y-4">
              <div className="bg-neutral-900 border border-neutral-800 rounded-xl overflow-hidden">
                <table className="w-full text-left text-xs">
                  <thead className="bg-neutral-950 text-neutral-400 uppercase text-[10px] tracking-wider border-b border-neutral-800">
                    <tr>
                      <th className="p-3">Reference</th>
                      <th className="p-3">Driver & Vehicle</th>
                      <th className="p-3">Pickup → Destination</th>
                      <th className="p-3">Departure / Return Odometer</th>
                      <th className="p-3">Actual Distance (Odo vs GPS)</th>
                      <th className="p-3">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-800 text-neutral-300">
                    {trips.map(trip => {
                      const drv = drivers.find(d => d.id === trip.driverId);
                      const veh = vehicles.find(v => v.id === trip.vehicleId);
                      const odoDelta = trip.signInOdometer && trip.signOutOdometer ? (trip.signInOdometer - trip.signOutOdometer) : null;
                      
                      return (
                        <tr key={trip.id} className="hover:bg-neutral-800/40">
                          <td className="p-3 font-mono text-[10px]">
                            {trip.tripRequestNumber}
                            <span className="block text-[9px] text-neutral-500">{new Date(trip.requestedAt).toLocaleDateString()}</span>
                          </td>
                          <td className="p-3">
                            <span className="font-bold text-white">{drv?.name}</span>
                            <span className="block font-mono text-[10px] text-amber-500">{veh?.registrationNumber}</span>
                          </td>
                          <td className="p-3">
                            <p className="font-semibold text-white">{trip.pickupPoint} → {trip.destination}</p>
                            <p className="text-[10px] text-neutral-400 truncate max-w-xs">{trip.purpose}</p>
                          </td>
                          <td className="p-3 font-mono">
                            {trip.signOutOdometer ? `${trip.signOutOdometer.toLocaleString()} KM` : "N/A"}
                            <span className="block text-neutral-500">→ {trip.signInOdometer ? `${trip.signInOdometer.toLocaleString()} KM` : "In Progress"}</span>
                          </td>
                          <td className="p-3 font-mono">
                            {odoDelta ? `${odoDelta} KM` : "Calculating..."}
                            <span className="block text-rose-400 text-[10px]">GPS: {trip.gpsDistanceKm} KM</span>
                          </td>
                          <td className="p-3">
                            <span className={`text-[10px] px-2 py-0.5 rounded font-mono ${
                              trip.status === TripStatus.Completed ? "bg-emerald-500/10 text-emerald-400" :
                              trip.status === TripStatus.Flagged ? "bg-rose-500/10 text-rose-400" :
                              "bg-amber-500/10 text-amber-500"
                            }`}>
                              {trip.status}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* VEHICLES MODULE */}
          {activeSidebar === "vehicles" && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {vehicles.map(v => {
                  const driver = drivers.find(d => d.id === v.assignedDriverId);
                  return (
                    <div
                      key={v.id}
                      onClick={() => setSelectedVehicle(v)}
                      className="bg-neutral-900 border border-neutral-800 rounded-xl p-4 cursor-pointer hover:border-neutral-700 transition"
                    >
                      <div className="flex justify-between items-start mb-3">
                        <div>
                          <span className="bg-amber-500/10 text-amber-500 text-[10px] px-2 py-0.5 rounded-full font-mono font-bold">
                            {v.type}
                          </span>
                          <h3 className="text-sm font-black text-white mt-1.5">{v.make} {v.model}</h3>
                          <p className="font-mono text-xs text-neutral-400">{v.registrationNumber}</p>
                        </div>
                        <span className={`text-[10px] px-2 py-0.5 rounded font-mono ${
                          v.status === VehicleStatus.Active ? "bg-emerald-500/20 text-emerald-400" :
                          v.status === VehicleStatus.UnderMaintenance ? "bg-blue-500/20 text-blue-400" :
                          v.status === VehicleStatus.Grounded ? "bg-rose-500/20 text-rose-400" : "bg-neutral-800 text-neutral-400"
                        }`}>
                          {v.status}
                        </span>
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-[11px] text-neutral-400 font-mono mb-3">
                        <div>
                          <span>Driver</span>
                          <p className="text-white font-bold">{driver ? driver.name : "Unassigned"}</p>
                        </div>
                        <div>
                          <span>Odometer</span>
                          <p className="text-white font-bold">{v.currentOdometer.toLocaleString()} KM</p>
                        </div>
                      </div>

                      <div className="pt-2 border-t border-neutral-800 text-[10px] text-neutral-500 flex justify-between">
                        <span>Fuel cap: {v.tankCapacity} L</span>
                        <span>Fuel used this month: {v.currentMonthFuelUsed} L</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* DRIVERS PROFILE MODULE */}
          {activeSidebar === "drivers" && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {drivers.map(drv => (
                  <div
                    key={drv.id}
                    className="bg-neutral-900 border border-neutral-800 rounded-xl p-4 flex flex-col md:flex-row justify-between items-start md:items-center space-y-4 md:space-y-0"
                  >
                    <div className="flex items-center space-x-3.5">
                      <img src={drv.photoUrl} alt={drv.name} className="w-14 h-14 rounded-full object-cover border-2 border-neutral-800 shrink-0" />
                      <div>
                        <h3 className="text-sm font-black text-white">{drv.name}</h3>
                        <p className="text-[10px] text-neutral-400 font-mono">License Class: {drv.licenseClass}</p>
                        <p className="text-[10px] text-neutral-500 font-mono">Staff ID: {drv.staffNumber}</p>
                      </div>
                    </div>

                    <div className="text-right space-y-2">
                      <div className="font-mono text-[11px]">
                        <span className="text-neutral-400">Driver Risk Rating: </span>
                        <span className={`font-black ${drv.riskScore > 50 ? "text-rose-400" : "text-emerald-400"}`}>{drv.riskScore}/100</span>
                      </div>
                      <div className="font-mono text-[11px]">
                        <span className="text-neutral-400">Performance Index: </span>
                        <span className="text-white font-black">{drv.performanceScore}%</span>
                      </div>
                      <span className={`inline-block text-[9px] px-2 py-0.5 rounded font-mono font-bold ${
                        drv.status === DriverStatus.Active ? "bg-emerald-500/20 text-emerald-400" : "bg-rose-500/20 text-rose-400"
                      }`}>
                        {drv.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* FUEL AUDIT MODULE */}
          {activeSidebar === "fuel" && (
            <FuelTheftDashboard
              vehicles={vehicles}
              trips={trips}
              fuelRequests={fuelRequests}
              drivers={drivers}
              onUpdateFuelRequests={onUpdateFuelRequests}
              onAddAuditLog={onAddAuditLog}
              activeRole={activeRole}
            />
          )}

          {/* MAINTENANCE MODULE */}
          {activeSidebar === "maintenance" && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {maintenanceRequests.map(mr => {
                  const veh = vehicles.find(v => v.id === mr.vehicleId);
                  const drv = drivers.find(d => d.id === mr.driverId);
                  
                  return (
                    <div key={mr.id} className="bg-neutral-900 border border-neutral-800 rounded-xl p-4 space-y-4">
                      <div className="flex justify-between items-start">
                        <div>
                          <span className={`text-[9px] px-2 py-0.5 rounded-full font-bold uppercase ${
                            mr.category === "Emergency" ? "bg-rose-500/20 text-rose-400 animate-pulse" : "bg-blue-500/20 text-blue-400"
                          }`}>
                            {mr.category}
                          </span>
                          <h4 className="text-xs font-black text-white mt-1.5">{mr.description}</h4>
                          <p className="text-[10px] text-neutral-400">Reporter: {drv?.name} | Vehicle: {veh?.registrationNumber}</p>
                        </div>
                        <span className="text-[10px] bg-neutral-950 px-2.5 py-1 rounded font-mono font-bold text-amber-500">
                          {mr.status}
                        </span>
                      </div>

                      <div className="grid grid-cols-3 gap-2 font-mono text-[10px] bg-neutral-950 p-2.5 rounded border border-neutral-900">
                        <div>
                          <span>Odometer</span>
                          <p className="text-white font-bold">{mr.odometer}</p>
                        </div>
                        <div>
                          <span>Quoted Cost</span>
                          <p className="text-white font-bold">${mr.quotationAmount || "Awaiting Quotation"}</p>
                        </div>
                        <div>
                          <span>Dispatched Garage</span>
                          <p className="text-white font-bold truncate">{mr.garageName || "Not assigned"}</p>
                        </div>
                      </div>

                      {mr.status === MaintenanceStatus.Pending && mr.quotationAmount && (
                        <div className="p-3 bg-neutral-950 rounded border border-neutral-800 flex justify-between items-center text-xs">
                          <span className="text-neutral-400 font-mono">Approve Quotation? (${mr.quotationAmount})</span>
                          <button
                            onClick={() => handleApproveRepair(mr.id, mr.quotationAmount || 0)}
                            className="bg-amber-500 hover:bg-amber-600 text-neutral-950 px-3 py-1.5 rounded-lg font-bold"
                          >
                            Approve Repair Work
                          </button>
                        </div>
                      )}

                      {mr.partsReplaced && mr.partsReplaced.length > 0 && (
                        <div className="space-y-1.5">
                          <span className="text-[10px] text-neutral-500 font-mono uppercase block">REMOVED AND INSTALLED PARTS REGISTER</span>
                          <div className="divide-y divide-neutral-800/60">
                            {mr.partsReplaced.map((part, pIdx) => (
                              <div key={pIdx} className="py-1 flex justify-between text-[11px]">
                                <span className="text-white font-semibold">{part.partName}</span>
                                <span className="font-mono text-neutral-500">Installed Serial: <span className="text-emerald-400">{part.serialInstalled}</span></span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* PREDICTIVE MAINTENANCE FORECAST MODULE */}
          {activeSidebar === "maintenance-forecast" && (
            <div className="space-y-6">
              
              {/* Header card explaining how prediction models work */}
              <div className="bg-gradient-to-r from-neutral-900 to-amber-950/20 border border-neutral-800 p-5 rounded-2xl relative overflow-hidden">
                <div className="absolute top-0 right-0 w-80 h-80 bg-amber-500/5 rounded-full blur-3xl pointer-events-none"></div>
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                  <div className="space-y-1.5">
                    <div className="flex items-center space-x-2 text-amber-500">
                      <Sparkles className="w-5 h-5 animate-pulse" />
                      <span className="text-xs font-black uppercase tracking-widest font-mono">Predictive Machine Wear Analytics</span>
                    </div>
                    <h3 className="text-base font-extrabold text-white">AI-Driven Fleet Service Forecasting & Part Lifespans</h3>
                    <p className="text-xs text-neutral-400 max-w-2xl leading-relaxed">
                      By correlating historical GPS distance telemetry, daily odometer accumulation rates, and the spare parts ledger, the model dynamically predicts remaining lifetime hours and provides targeted maintenance recommendations.
                    </p>
                  </div>
                  
                  {/* Stressor Simulation Control */}
                  <div className="bg-neutral-950 p-3.5 rounded-xl border border-neutral-800/80 space-y-2 shrink-0 w-full md:w-auto">
                    <span className="text-[10px] text-amber-500 font-bold uppercase tracking-wider block font-mono">Operations Stressor Simulator</span>
                    <p className="text-[10px] text-neutral-400 max-w-xs">
                      Simulate high utilization on active routes to stress-test part wear limits across the fleet.
                    </p>
                    <button
                      onClick={handleSimulateMileageAccumulation}
                      className="w-full bg-amber-500 hover:bg-amber-600 text-neutral-950 font-black text-xs py-2 px-3 rounded-lg flex items-center justify-center space-x-1.5 transition active:scale-98"
                    >
                      <RotateCw className="w-3.5 h-3.5" />
                      <span>Simulate +1,500 KM Fleet Travel</span>
                    </button>
                  </div>
                </div>
              </div>

              {/* Dynamic Fleet Metrics Scorecard */}
              {(() => {
                // Precompute global fleet aggregates
                let totalDailyMileage = 0;
                let activeVehicleCount = 0;
                let totalWearSum = 0;
                let totalComponentsCount = 0;
                let criticalAlertsCount = 0;

                const forecastData = vehicles.map(vehicle => {
                  const vehicleTrips = trips.filter(t => t.vehicleId === vehicle.id && t.status === TripStatus.Completed);
                  let avgDailyMileage = 40.0;
                  if (vehicle.assignedDepartment.includes("Emergency")) avgDailyMileage = 85.0;
                  else if (vehicle.assignedDepartment.includes("Staff Shuttle")) avgDailyMileage = 65.0;
                  else if (vehicle.assignedDepartment.includes("Logistics")) avgDailyMileage = 55.0;

                  if (vehicleTrips.length > 0) {
                    const totalKm = vehicleTrips.reduce((sum, t) => sum + (t.gpsDistanceKm || (t.signInOdometer && t.signOutOdometer ? t.signInOdometer - t.signOutOdometer : 0) || 45), 0);
                    const calculatedAvg = totalKm / vehicleTrips.length;
                    const multiplier = vehicle.assignedDepartment.includes("Emergency") ? 1.8 : vehicle.assignedDepartment.includes("Staff Shuttle") ? 1.4 : 1.1;
                    avgDailyMileage = Math.round(calculatedAvg * multiplier * 10) / 10;
                  }
                  
                  if (vehicle.status === VehicleStatus.Grounded) {
                    avgDailyMileage = 0.0;
                  }

                  totalDailyMileage += avgDailyMileage;
                  if (vehicle.status === VehicleStatus.Active) {
                    activeVehicleCount++;
                  }

                  const completedMaint = maintenanceRequests.filter(m => m.vehicleId === vehicle.id && (m.status === MaintenanceStatus.Completed || m.status === MaintenanceStatus.Verified));
                  
                  const findLastReplacedOdometer = (keywords: string[], fallbackOffset: number) => {
                    let maxOdo = -1;
                    completedMaint.forEach(m => {
                      const matchesDesc = keywords.some(kw => m.description.toLowerCase().includes(kw));
                      const matchesParts = m.partsReplaced?.some(p => keywords.some(kw => p.partName.toLowerCase().includes(kw)));
                      if ((matchesDesc || matchesParts) && m.odometer > maxOdo) {
                        maxOdo = m.odometer;
                      }
                    });
                    if (maxOdo !== -1) return maxOdo;
                    return Math.max(0, vehicle.currentOdometer - fallbackOffset);
                  };

                  const lastOilOdo = findLastReplacedOdometer(["oil", "lubricant", "routine"], 2200);
                  const lastBrakesOdo = findLastReplacedOdometer(["brake", "pad", "rotor", "caliper"], 13200);
                  const lastFiltersOdo = findLastReplacedOdometer(["filter", "air filter", "fuel filter"], 4200);
                  
                  let lastTyresOdo = findLastReplacedOdometer(["tyre", "tire", "alignment"], 18000);
                  const vehicleTyres = tyres.filter(t => t.vehicleId === vehicle.id);
                  if (vehicleTyres.length > 0) {
                    const minInstalledOdo = Math.min(...vehicleTyres.map(t => t.installedAtOdometer));
                    if (minInstalledOdo > 0) {
                      lastTyresOdo = minInstalledOdo;
                    }
                  }

                  const comps = [
                    { name: "Engine Oil", interval: 5000, lastOdo: lastOilOdo },
                    { name: "Brake Pads", interval: 15000, lastOdo: lastBrakesOdo },
                    { name: "Filters", interval: 10000, lastOdo: lastFiltersOdo },
                    { name: "Tyres", interval: 40000, lastOdo: lastTyresOdo }
                  ].map(c => {
                    let runKm = Math.max(0, vehicle.currentOdometer - c.lastOdo);
                    
                    // Force overdue brakes on Musa's vehicle v3
                    if (vehicle.id === "v3" && c.name === "Brake Pads") {
                      runKm = Math.max(runKm, c.interval + 800);
                    }
                    if (vehicle.id === "v3" && c.name === "Tyres") {
                      runKm = Math.max(runKm, c.interval + 150);
                    }

                    const remainingKm = Math.max(0, c.interval - runKm);
                    const wearPercentage = Math.min(100, Math.round((runKm / c.interval) * 100));
                    
                    totalWearSum += wearPercentage;
                    totalComponentsCount++;

                    if (wearPercentage >= 90) {
                      criticalAlertsCount++;
                    }

                    return { ...c, remainingKm, wearPercentage };
                  });

                  return { vehicle, avgDailyMileage, comps };
                });

                const fleetHealthScore = totalComponentsCount > 0 
                  ? Math.round(100 - (totalWearSum / totalComponentsCount)) 
                  : 100;

                return (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                      <div>
                        <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider block">Average Fleet Wear Index</span>
                        <h3 className="text-2xl font-black mt-1 text-white">{fleetHealthScore}% <span className="text-xs text-neutral-500 font-normal">health</span></h3>
                        <p className="text-[10px] text-emerald-400 font-mono mt-1">✓ Expected life limits optimal</p>
                      </div>
                      <div className="bg-emerald-500/10 text-emerald-400 p-2.5 rounded-lg">
                        <Activity className="w-5 h-5" />
                      </div>
                    </div>

                    <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                      <div>
                        <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider block">Total Fleet Travel / Day</span>
                        <h3 className="text-2xl font-black mt-1 text-white">{Math.round(totalDailyMileage)} <span className="text-xs text-neutral-500 font-normal">KM</span></h3>
                        <p className="text-[10px] text-neutral-400 font-mono mt-1">across {vehicles.filter(v => v.status === VehicleStatus.Active).length} dispatched routes</p>
                      </div>
                      <div className="bg-amber-500/10 text-amber-500 p-2.5 rounded-lg">
                        <Compass className="w-5 h-5" />
                      </div>
                    </div>

                    <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                      <div>
                        <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider block">Urgent Wear Alerts</span>
                        <h3 className={`text-2xl font-black mt-1 ${criticalAlertsCount > 0 ? "text-rose-400 animate-pulse" : "text-white"}`}>{criticalAlertsCount}</h3>
                        <p className="text-[10px] text-rose-400 font-mono mt-1">⚠ Wear exceeds 90% threshold</p>
                      </div>
                      <div className="bg-rose-500/10 text-rose-400 p-2.5 rounded-lg">
                        <AlertTriangle className="w-5 h-5" />
                      </div>
                    </div>

                    <div className="bg-neutral-900 p-4 rounded-xl border border-neutral-800 flex justify-between items-start">
                      <div>
                        <span className="text-[10px] text-neutral-500 font-bold uppercase tracking-wider block">Forecast Period</span>
                        <h3 className="text-2xl font-black mt-1 text-white">30 Days</h3>
                        <p className="text-[10px] text-neutral-400 font-mono mt-1">Continuous calendar estimation</p>
                      </div>
                      <div className="bg-blue-500/10 text-blue-400 p-2.5 rounded-lg">
                        <Clock className="w-5 h-5" />
                      </div>
                    </div>
                  </div>
                );
              })()}

              {/* Predictive Analysis Cards per Vehicle */}
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h4 className="text-xs font-black uppercase text-neutral-400 tracking-wider">Vehicle Wear Diagnostics & Quick Dispatches</h4>
                  <span className="text-[10px] text-neutral-500 font-mono uppercase">Calculated continuously based on 2026 UTC Odometer logs</span>
                </div>

                {vehicles.map(vehicle => {
                  const driver = drivers.find(d => d.id === vehicle.assignedDriverId);
                  
                  // Compute individual metrics
                  const vehicleTrips = trips.filter(t => t.vehicleId === vehicle.id && t.status === TripStatus.Completed);
                  let avgDailyMileage = 40.0;
                  if (vehicle.assignedDepartment.includes("Emergency")) avgDailyMileage = 85.0;
                  else if (vehicle.assignedDepartment.includes("Staff Shuttle")) avgDailyMileage = 65.0;
                  else if (vehicle.assignedDepartment.includes("Logistics")) avgDailyMileage = 55.0;

                  if (vehicleTrips.length > 0) {
                    const totalKm = vehicleTrips.reduce((sum, t) => sum + (t.gpsDistanceKm || (t.signInOdometer && t.signOutOdometer ? t.signInOdometer - t.signOutOdometer : 0) || 45), 0);
                    const calculatedAvg = totalKm / vehicleTrips.length;
                    const multiplier = vehicle.assignedDepartment.includes("Emergency") ? 1.8 : vehicle.assignedDepartment.includes("Staff Shuttle") ? 1.4 : 1.1;
                    avgDailyMileage = Math.round(calculatedAvg * multiplier * 10) / 10;
                  }

                  if (vehicle.status === VehicleStatus.Grounded) {
                    avgDailyMileage = 0;
                  }

                  const completedMaint = maintenanceRequests.filter(m => m.vehicleId === vehicle.id && (m.status === MaintenanceStatus.Completed || m.status === MaintenanceStatus.Verified));
                  
                  const findLastReplacedOdometer = (keywords: string[], fallbackOffset: number) => {
                    let maxOdo = -1;
                    completedMaint.forEach(m => {
                      const matchesDesc = keywords.some(kw => m.description.toLowerCase().includes(kw));
                      const matchesParts = m.partsReplaced?.some(p => keywords.some(kw => p.partName.toLowerCase().includes(kw)));
                      if ((matchesDesc || matchesParts) && m.odometer > maxOdo) {
                        maxOdo = m.odometer;
                      }
                    });
                    if (maxOdo !== -1) return maxOdo;
                    return Math.max(0, vehicle.currentOdometer - fallbackOffset);
                  };

                  const OIL_INTERVAL = 5000;
                  const BRAKES_INTERVAL = 15000;
                  const FILTERS_INTERVAL = 10000;
                  const TYRES_INTERVAL = 40000;

                  const lastOilOdo = findLastReplacedOdometer(["oil", "lubricant", "routine"], 2200);
                  const lastBrakesOdo = findLastReplacedOdometer(["brake", "pad", "rotor", "caliper"], 13200);
                  const lastFiltersOdo = findLastReplacedOdometer(["filter", "air filter", "fuel filter"], 4200);
                  
                  let lastTyresOdo = findLastReplacedOdometer(["tyre", "tire", "alignment"], 18000);
                  const vehicleTyres = tyres.filter(t => t.vehicleId === vehicle.id);
                  if (vehicleTyres.length > 0) {
                    const minInstalledOdo = Math.min(...vehicleTyres.map(t => t.installedAtOdometer));
                    if (minInstalledOdo > 0) {
                      lastTyresOdo = minInstalledOdo;
                    }
                  }

                  const comps = [
                    { name: "Engine Oil", label: "Engine Oil & Filter", interval: OIL_INTERVAL, lastOdo: lastOilOdo, key: "Oil" as const, unit: "L" },
                    { name: "Brake Pads", label: "Brake Pads & Calipers", interval: BRAKES_INTERVAL, lastOdo: lastBrakesOdo, key: "Brakes" as const, unit: "Set" },
                    { name: "Filters", label: "Air & Fuel Filters", interval: FILTERS_INTERVAL, lastOdo: lastFiltersOdo, key: "Filters" as const, unit: "Units" },
                    { name: "Tyres", label: "Tyre Wear & Rotation", interval: TYRES_INTERVAL, lastOdo: lastTyresOdo, key: "Full" as const, unit: "PCS" }
                  ].map(c => {
                    let runKm = Math.max(0, vehicle.currentOdometer - c.lastOdo);
                    
                    // Force overdue brakes and tyres on Musa's vehicle v3
                    if (vehicle.id === "v3" && c.name === "Brake Pads") {
                      runKm = Math.max(runKm, c.interval + 800);
                    }
                    if (vehicle.id === "v3" && c.name === "Tyres") {
                      runKm = Math.max(runKm, c.interval + 150);
                    }

                    const remainingKm = Math.max(0, c.interval - runKm);
                    const wearPercentage = Math.min(100, Math.round((runKm / c.interval) * 100));
                    const daysRemaining = avgDailyMileage > 0 ? Math.round(remainingKm / avgDailyMileage) : 9999;
                    
                    let status: "Healthy" | "Caution" | "Overdue" = "Healthy";
                    if (runKm >= c.interval) {
                      status = "Overdue";
                    } else if (remainingKm <= c.interval * 0.2) {
                      status = "Caution";
                    }

                    return { ...c, runKm, remainingKm, wearPercentage, daysRemaining, status };
                  });

                  // Calculate exact next service details
                  const overdueComps = comps.filter(c => c.status === "Overdue");
                  const cautionComps = comps.filter(c => c.status === "Caution");
                  
                  let nextServiceDays = 9999;
                  let nextServicePart = "None";
                  let overallStatus: "Healthy" | "Caution" | "Overdue" = "Healthy";

                  if (overdueComps.length > 0) {
                    nextServiceDays = 0;
                    nextServicePart = overdueComps[0].label;
                    overallStatus = "Overdue";
                  } else {
                    const sortedComps = [...comps].sort((a, b) => a.daysRemaining - b.daysRemaining);
                    nextServiceDays = sortedComps[0].daysRemaining;
                    nextServicePart = sortedComps[0].label;
                    overallStatus = sortedComps[0].status;
                  }

                  // Predict service date
                  const baseDate = new Date();
                  baseDate.setDate(baseDate.getDate() + (nextServiceDays === 9999 ? 365 : nextServiceDays));
                  const formattedDate = baseDate.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });

                  return (
                    <div key={vehicle.id} className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 space-y-5 shadow-lg relative overflow-hidden">
                      
                      {/* Left highlights background indicator based on status */}
                      <div className={`absolute top-0 left-0 w-1.5 h-full ${
                        overallStatus === "Overdue" ? "bg-rose-500 animate-pulse" :
                        overallStatus === "Caution" ? "bg-amber-500" :
                        "bg-emerald-500"
                      }`}></div>

                      {/* Top Row: Vehicle Summary */}
                      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 pl-2">
                        <div className="flex items-center space-x-3.5">
                          <div className={`w-11 h-11 rounded-xl flex items-center justify-center text-neutral-950 font-bold shrink-0 ${
                            overallStatus === "Overdue" ? "bg-rose-500 text-white" :
                            overallStatus === "Caution" ? "bg-amber-500 text-neutral-950" :
                            "bg-emerald-500 text-neutral-950"
                          }`}>
                            <Car className="w-5.5 h-5.5" />
                          </div>
                          <div>
                            <div className="flex items-center space-x-2">
                              <h4 className="text-sm font-black text-white">{vehicle.make} {vehicle.model}</h4>
                              <span className="text-[10px] bg-neutral-950 px-2 py-0.5 rounded border border-neutral-800 text-neutral-400 font-mono font-bold">{vehicle.registrationNumber}</span>
                            </div>
                            <p className="text-[11px] text-neutral-400 font-mono">
                              Odometer: <span className="text-white font-bold">{vehicle.currentOdometer.toLocaleString()} KM</span> | Dept: {vehicle.assignedDepartment}
                            </p>
                          </div>
                        </div>

                        {/* Usage rate & dynamic prediction pill */}
                        <div className="flex flex-col md:items-end font-mono text-[11px] space-y-1 w-full md:w-auto">
                          <div className="flex justify-between md:justify-end items-center gap-2">
                            <span className="text-neutral-500">Odo Wear Rate:</span>
                            <span className="text-white font-bold">{avgDailyMileage} KM/day</span>
                          </div>
                          
                          <div className="flex justify-between md:justify-end items-center gap-2">
                            <span className="text-neutral-500">Assigned Driver:</span>
                            <span className="text-white font-bold">{driver ? driver.name : "Unassigned"}</span>
                          </div>

                          <div className="pt-1.5 flex gap-2">
                            {overallStatus === "Overdue" ? (
                              <span className="bg-rose-950/40 text-rose-400 border border-rose-500/20 text-[9px] px-2 py-0.5 rounded font-black uppercase animate-pulse">
                                Overdue: {nextServicePart}
                              </span>
                            ) : (
                              <span className={`text-[9px] px-2 py-0.5 rounded border font-bold uppercase ${
                                overallStatus === "Caution" ? "bg-amber-950/40 text-amber-400 border-amber-500/20" : "bg-emerald-950/40 text-emerald-400 border-emerald-500/20"
                              }`}>
                                Service Due: {formattedDate} ({nextServiceDays === 9999 ? "No usage" : `${nextServiceDays} Days`})
                              </span>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Component breakdown meters */}
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pl-2">
                        {comps.map((comp, cIdx) => {
                          const isWarning = comp.status === "Overdue";
                          const isCaution = comp.status === "Caution";

                          return (
                            <div key={cIdx} className="bg-neutral-950 p-3 rounded-xl border border-neutral-850 space-y-2 relative">
                              <div className="flex justify-between items-start">
                                <span className="text-[10px] text-neutral-400 font-bold">{comp.label}</span>
                                <span className={`text-[9px] font-mono font-black ${
                                  isWarning ? "text-rose-400" : isCaution ? "text-amber-400" : "text-emerald-400"
                                }`}>
                                  {comp.wearPercentage}% worn
                                </span>
                              </div>

                              {/* Progress bar */}
                              <div className="w-full bg-neutral-900 rounded-full h-2 overflow-hidden border border-neutral-850">
                                <div
                                  className={`h-full rounded-full transition-all duration-500 ${
                                    isWarning ? "bg-rose-500" : isCaution ? "bg-amber-500" : "bg-emerald-500"
                                  }`}
                                  style={{ width: `${comp.wearPercentage}%` }}
                                ></div>
                              </div>

                              {/* Component stats */}
                              <div className="flex justify-between text-[10px] font-mono text-neutral-500">
                                <span>Interval: {comp.interval.toLocaleString()} KM</span>
                                {isWarning ? (
                                  <span className="text-rose-400 font-bold uppercase animate-pulse">OVERDUE</span>
                                ) : (
                                  <span className="text-neutral-300">{(comp.remainingKm).toLocaleString()} KM left</span>
                                )}
                              </div>
                              
                              {/* Sub details */}
                              <div className="text-[9px] text-neutral-600 font-mono flex justify-between">
                                <span>Last Service Odo:</span>
                                <span className="text-neutral-400 font-semibold">{comp.lastOdo.toLocaleString()} KM</span>
                              </div>
                            </div>
                          );
                        })}
                      </div>

                      {/* Dispatch & Quick Preventative Service Action Panel */}
                      <div className="pt-3 border-t border-neutral-800/80 flex flex-wrap justify-between items-center gap-3 pl-2">
                        <div className="flex items-center space-x-1">
                          <span className="text-[10px] text-neutral-500 font-mono">Completed Services in Log:</span>
                          <span className="text-[10px] bg-neutral-950 px-2 py-0.5 border border-neutral-850 rounded text-neutral-300 font-mono font-bold">
                            {completedMaint.length} sessions
                          </span>
                        </div>

                        <div className="flex flex-wrap items-center gap-2">
                          <span className="text-[10px] text-neutral-500 font-mono uppercase font-bold mr-1">Perform Predictive Dispatch:</span>
                          
                          <button
                            onClick={() => handlePerformService(vehicle.id, "Oil")}
                            className="bg-neutral-950 hover:bg-neutral-800 text-white border border-neutral-800 text-[10px] font-bold py-1.5 px-3 rounded-lg transition"
                          >
                            Perform Oil Change
                          </button>

                          <button
                            onClick={() => handlePerformService(vehicle.id, "Brakes")}
                            className="bg-neutral-950 hover:bg-neutral-800 text-white border border-neutral-800 text-[10px] font-bold py-1.5 px-3 rounded-lg transition"
                          >
                            Overhaul Brakes
                          </button>

                          <button
                            onClick={() => handlePerformService(vehicle.id, "Filters")}
                            className="bg-neutral-950 hover:bg-neutral-800 text-white border border-neutral-800 text-[10px] font-bold py-1.5 px-3 rounded-lg transition"
                          >
                            Swap Air Filters
                          </button>

                          <button
                            onClick={() => handlePerformService(vehicle.id, "Full")}
                            className="bg-amber-500 hover:bg-amber-600 text-neutral-950 text-[10px] font-extrabold py-1.5 px-3.5 rounded-lg transition"
                          >
                            Perform 360° Overhaul
                          </button>
                        </div>
                      </div>

                    </div>
                  );
                })}
              </div>

            </div>
          )}

          {/* SPARE PARTS LEDGER */}
          {activeSidebar === "inventory" && (
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider">Store Inventory & Part catalogues</h3>
                <button
                  onClick={() => setShowAddPart(true)}
                  className="bg-amber-500 hover:bg-amber-600 text-neutral-950 text-xs px-3 py-1.5 rounded-lg font-bold flex items-center space-x-1"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Register Spare Part</span>
                </button>
              </div>

              <div className="bg-neutral-900 border border-neutral-800 rounded-xl overflow-hidden">
                <table className="w-full text-left text-xs">
                  <thead className="bg-neutral-950 text-neutral-400 uppercase text-[10px] tracking-wider border-b border-neutral-800">
                    <tr>
                      <th className="p-3">Part Details</th>
                      <th className="p-3">Compatible Models</th>
                      <th className="p-3">Ledger Cost</th>
                      <th className="p-3">Current Stock</th>
                      <th className="p-3">Reorder Alert Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-800 text-neutral-300">
                    {spareParts.map(part => (
                      <tr key={part.id} className="hover:bg-neutral-800/40">
                        <td className="p-3">
                          <span className="font-bold text-white block">{part.partName}</span>
                          <span className="font-mono text-[10px] text-neutral-500">Part No: {part.partNumber} | {part.category}</span>
                        </td>
                        <td className="p-3 font-mono text-[11px]">{part.compatibleVehicleModel}</td>
                        <td className="p-3 font-mono text-white font-bold">${part.unitCost}</td>
                        <td className="p-3 font-mono text-white font-bold">{part.stockQty} Units</td>
                        <td className="p-3">
                          <span className={`text-[10px] px-2 py-0.5 rounded font-mono ${
                            part.stockQty <= part.reorderLevel ? "bg-rose-500/20 text-rose-400 animate-pulse font-bold" : "bg-emerald-500/20 text-emerald-400"
                          }`}>
                            {part.stockQty <= part.reorderLevel ? "Reorder Alert!" : "Healthy Stock"}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* POLICY ENGINE */}
          {activeSidebar === "policy" && (
            <div className="space-y-4">
              <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-4">
                <div className="flex items-center space-x-2 text-amber-500 mb-3">
                  <Sliders className="w-5 h-5" />
                  <h3 className="text-sm font-extrabold text-white">Rule Configurator & Compliance Enforcement Thresholds</h3>
                </div>
                <p className="text-xs text-neutral-400">
                  Update operational parameters. System automatically scans GPS data, odometer updates, and parts replacement cost limits based on these active rules.
                </p>
              </div>

              <div className="space-y-3">
                {policyRules.map(rule => (
                  <div key={rule.id} className="bg-neutral-900 border border-neutral-800 p-4 rounded-xl flex justify-between items-center text-xs">
                    <div className="space-y-1 w-2/3">
                      <span className="text-[9px] font-bold text-amber-500 uppercase tracking-widest block">{rule.category} Rules</span>
                      <h4 className="text-white font-bold text-xs">{rule.name}</h4>
                      <p className="text-neutral-400">{rule.description}</p>
                    </div>

                    <div className="flex items-center space-x-3 shrink-0">
                      {editingRuleId === rule.id ? (
                        <div className="flex items-center space-x-2">
                          <input
                            type="text"
                            value={editingRuleValue}
                            onChange={(e) => setEditingRuleValue(e.target.value)}
                            className="bg-neutral-950 border border-neutral-800 text-xs text-white p-1.5 rounded focus:outline-none"
                          />
                          <button
                            onClick={() => handleSavePolicyRule(rule.id)}
                            className="bg-emerald-500 text-neutral-950 p-1.5 rounded-lg hover:bg-emerald-600"
                          >
                            <Check className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => setEditingRuleId(null)}
                            className="bg-neutral-800 text-neutral-400 p-1.5 rounded-lg hover:bg-neutral-700"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center space-x-4">
                          <span className="font-mono text-xs text-white font-black bg-neutral-950 px-3 py-1.5 rounded-lg border border-neutral-800">
                            {rule.value}
                          </span>
                          <button
                            onClick={() => {
                              setEditingRuleId(rule.id);
                              setEditingRuleValue(rule.value);
                            }}
                            className="text-amber-500 hover:text-amber-400 font-bold"
                          >
                            Modify
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* APPROVALS WORK QUEUE */}
          {activeSidebar === "approvals" && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                
                {/* Fuel Claims pending */}
                <div className="space-y-3">
                  <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider">Pending Fuel Allocations</h3>
                  {fuelRequests.filter(f => f.status === "Pending").map(fr => {
                    const drv = drivers.find(d => d.id === fr.driverId);
                    const veh = vehicles.find(v => v.id === fr.vehicleId);
                    return (
                      <div key={fr.id} className="bg-neutral-900 border border-neutral-800 p-4 rounded-xl space-y-3 text-xs">
                        <div className="flex justify-between items-center">
                          <span className="font-mono text-[10px] text-neutral-500">Request: {fr.id}</span>
                          <span className="text-amber-500 font-bold">{fr.requestedLiters} L Requested</span>
                        </div>
                        <p className="text-white font-bold">{fr.stationName}</p>
                        <p className="text-neutral-400">Driver: {drv?.name} | Vehicle: {veh?.registrationNumber}</p>
                        <div className="flex space-x-2 pt-2 border-t border-neutral-850">
                          <button
                            onClick={() => handleApproveFuel(fr.id)}
                            className="bg-amber-500 hover:bg-amber-600 text-neutral-950 font-bold py-1 px-3 rounded text-[11px]"
                          >
                            Approve Fuel Voucher
                          </button>
                        </div>
                      </div>
                    );
                  })}
                  {fuelRequests.filter(f => f.status === "Pending").length === 0 && (
                    <p className="text-xs text-neutral-500 italic">No fuel vouchers in pending approval queue.</p>
                  )}
                </div>

                {/* Repair work orders pending */}
                <div className="space-y-3">
                  <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider">Pending Repair Quotations</h3>
                  {maintenanceRequests.filter(m => m.status === MaintenanceStatus.Pending && m.quotationAmount).map(mr => {
                    const drv = drivers.find(d => d.id === mr.driverId);
                    const veh = vehicles.find(v => v.id === mr.vehicleId);
                    return (
                      <div key={mr.id} className="bg-neutral-900 border border-neutral-800 p-4 rounded-xl space-y-3 text-xs">
                        <div className="flex justify-between items-center">
                          <span className="font-mono text-[10px] text-neutral-500">Repair Order: {mr.id}</span>
                          <span className="text-rose-400 font-bold">${mr.quotationAmount} Quotation</span>
                        </div>
                        <p className="text-white font-bold truncate">{mr.description}</p>
                        <p className="text-neutral-400">Driver: {drv?.name} | Vehicle: {veh?.registrationNumber}</p>
                        <div className="flex space-x-2 pt-2 border-t border-neutral-850">
                          <button
                            onClick={() => handleApproveRepair(mr.id, mr.quotationAmount || 0)}
                            className="bg-amber-500 hover:bg-amber-600 text-neutral-950 font-bold py-1 px-3 rounded text-[11px]"
                          >
                            Approve Repair Quotation
                          </button>
                        </div>
                      </div>
                    );
                  })}
                  {maintenanceRequests.filter(m => m.status === MaintenanceStatus.Pending && m.quotationAmount).length === 0 && (
                    <p className="text-xs text-neutral-500 italic">No mechanical repairs in pending approval queue.</p>
                  )}
                </div>

              </div>
            </div>
          )}

          {/* AUDIT LOG TRAIL */}
          {activeSidebar === "audit-trail" && (
            <div className="space-y-4">
              <div className="bg-neutral-900 border border-neutral-800 rounded-xl overflow-hidden p-4">
                <div className="flex justify-between items-center mb-3">
                  <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider">IMMUTABLE SECURED AUDIT LOG</h3>
                  <span className="text-[10px] bg-neutral-950 px-2 py-0.5 border border-neutral-800 text-emerald-400 rounded font-mono">
                    ✓ Sealed Blackbox Audit Enabled
                  </span>
                </div>

                <div className="divide-y divide-neutral-800/80 font-mono text-[11px] max-h-[480px] overflow-y-auto space-y-2">
                  {auditLogs.map(log => (
                    <div key={log.id} className="py-2 space-y-1">
                      <div className="flex justify-between text-neutral-500">
                        <span>{new Date(log.timestamp).toLocaleTimeString()}</span>
                        <span className="text-amber-500">{log.userId} ({log.userRole})</span>
                      </div>
                      <p className="text-white">
                        <span className="text-neutral-400 font-bold uppercase tracking-wider">{log.action}: </span>
                        {log.details}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

        </div>
      </main>

      {/* OVERLAY DETAILS PANEL DRAWERS */}
      
      {/* Exception Investigation Overlay */}
      {selectedException && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-neutral-950 border border-neutral-800 rounded-3xl max-w-xl w-full p-6 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-[9px] bg-rose-500 text-neutral-950 px-2 py-0.5 rounded-full font-black uppercase font-mono mb-2 inline-block">
                  {selectedException.severity} severity investigation
                </span>
                <h3 className="text-base font-black text-white">{selectedException.title}</h3>
                <p className="text-xs text-neutral-400 font-mono">Log ID: {selectedException.id} | Timestamp: {selectedException.timestamp}</p>
              </div>
              <button onClick={() => setSelectedException(null)} className="text-neutral-500 hover:text-white">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="bg-neutral-900 p-4 rounded-2xl border border-neutral-800 space-y-2">
              <span className="text-[10px] text-neutral-400 uppercase tracking-wider block font-mono">Telemetry Anomaly Description:</span>
              <p className="text-xs text-neutral-200 leading-relaxed">{selectedException.description}</p>
            </div>

            {/* Simulated evidence photos based on type */}
            <div className="grid grid-cols-2 gap-3 text-center text-xs">
              <div className="bg-neutral-900 p-3 rounded-xl border border-neutral-800">
                <span className="text-[10px] text-neutral-500 block mb-1.5 font-mono">Odometer Log Match</span>
                <img
                  src="https://images.unsplash.com/photo-1527018601619-a508a2be00cd?auto=format&fit=crop&q=80&w=300"
                  alt="odometer"
                  className="rounded-lg object-cover h-24 w-full border border-neutral-800 mb-1"
                />
                <span className="text-[9px] text-neutral-400">Timestamp match OK</span>
              </div>
              <div className="bg-neutral-900 p-3 rounded-xl border border-neutral-800">
                <span className="text-[10px] text-neutral-500 block mb-1.5 font-mono">GPS Mapping Delta</span>
                <img
                  src="https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&q=80&w=300"
                  alt="gps"
                  className="rounded-lg object-cover h-24 w-full border border-neutral-800 mb-1"
                />
                <span className="text-[9px] text-rose-400 font-mono">Out-of-geofence route match ✓</span>
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs text-neutral-400 font-bold">Investigation Findings & Resolution Notes:</label>
              <textarea
                rows={3}
                value={resolutionNotes}
                onChange={(e) => setResolutionNotes(e.target.value)}
                className="w-full bg-neutral-900 border border-neutral-800 text-xs text-white rounded-xl p-3 focus:outline-none focus:ring-1 focus:ring-rose-500"
                placeholder="Log interviews, findings, warnings, fuel claim adjustments, or mechanical diagnostics. Notes will be sealed into immutable audit registry."
              />
            </div>

            <div className="flex space-x-2 pt-2">
              <button
                onClick={() => handleResolveException(selectedException.id)}
                className="bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs py-2.5 rounded-xl flex-1"
              >
                Seal Investigation & Resolve Flag
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Register Spare Part Modal */}
      {showAddPart && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <form onSubmit={handleAddSparePartSubmit} className="bg-neutral-950 border border-neutral-800 rounded-3xl max-w-md w-full p-6 space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-sm font-black text-white">Register Spare Part ledger</h3>
              <button type="button" onClick={() => setShowAddPart(false)} className="text-neutral-500 hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="text-[10px] text-neutral-400 block mb-1">Part Name:</label>
                <input
                  type="text"
                  required
                  value={newPart.partName}
                  onChange={(e) => setNewPart({ ...newPart, partName: e.target.value })}
                  className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  placeholder="e.g. Front Brake Rotors (Pair)"
                />
              </div>

              <div>
                <label className="text-[10px] text-neutral-400 block mb-1">Part Model / Serial ID:</label>
                <input
                  type="text"
                  required
                  value={newPart.partNumber}
                  onChange={(e) => setNewPart({ ...newPart, partNumber: e.target.value })}
                  className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  placeholder="e.g. TOY-ROT-4402"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Stock Category:</label>
                  <select
                    value={newPart.category}
                    onChange={(e) => setNewPart({ ...newPart, category: e.target.value })}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  >
                    <option value="Filters">Filters</option>
                    <option value="Brakes">Brakes</option>
                    <option value="Fluids">Fluids</option>
                    <option value="Electrical">Electrical</option>
                    <option value="Tyres">Tyres</option>
                  </select>
                </div>
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Compatible Vehicles:</label>
                  <input
                    type="text"
                    value={newPart.compatibleVehicleModel}
                    onChange={(e) => setNewPart({ ...newPart, compatibleVehicleModel: e.target.value })}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Unit Cost ($):</label>
                  <input
                    type="number"
                    value={newPart.unitCost}
                    onChange={(e) => setNewPart({ ...newPart, unitCost: parseInt(e.target.value) || 0 })}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">In Stock Quantity:</label>
                  <input
                    type="number"
                    value={newPart.stockQty}
                    onChange={(e) => setNewPart({ ...newPart, stockQty: parseInt(e.target.value) || 0 })}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>
                <div>
                  <label className="text-[10px] text-neutral-400 block mb-1">Reorder Alert Qty:</label>
                  <input
                    type="number"
                    value={newPart.reorderLevel}
                    onChange={(e) => setNewPart({ ...newPart, reorderLevel: parseInt(e.target.value) || 0 })}
                    className="w-full bg-neutral-900 border border-neutral-800 text-white rounded p-2 text-xs"
                  />
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-neutral-850">
              <button
                type="submit"
                className="w-full py-2.5 bg-amber-500 hover:bg-amber-600 text-neutral-950 font-extrabold text-xs rounded-xl"
              >
                Log Part into Storage Ledger
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Simple Vehicle Details Panel (Interactive Popover) */}
      {selectedVehicle && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-neutral-950 border border-neutral-800 rounded-3xl max-w-md w-full p-6 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="text-base font-black text-white">{selectedVehicle.make} {selectedVehicle.model}</h3>
                <span className="font-mono text-xs text-amber-500 font-bold">{selectedVehicle.registrationNumber}</span>
              </div>
              <button onClick={() => setSelectedVehicle(null)} className="text-neutral-500 hover:text-white">
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="space-y-3 text-xs divide-y divide-neutral-900">
              <div className="py-2 flex justify-between">
                <span className="text-neutral-400">Current Odometer</span>
                <span className="font-mono text-white font-bold">{selectedVehicle.currentOdometer.toLocaleString()} KM</span>
              </div>
              <div className="py-2 flex justify-between">
                <span className="text-neutral-400">Assigned Department</span>
                <span className="text-white font-semibold">{selectedVehicle.assignedDepartment}</span>
              </div>
              <div className="py-2 flex justify-between">
                <span className="text-neutral-400">Fuel Tank Capacity</span>
                <span className="text-white font-semibold">{selectedVehicle.tankCapacity} Liters</span>
              </div>
              <div className="py-2 flex justify-between">
                <span className="text-neutral-400">Expected Fuel Mileage</span>
                <span className="font-mono text-white font-bold">{selectedVehicle.expectedFuelConsumption} KM / Liter</span>
              </div>
              <div className="py-2 flex justify-between">
                <span className="text-neutral-400">GPS Tracker Status</span>
                <span className={`font-mono font-bold ${
                  selectedVehicle.trackerStatus === TrackerStatus.Active ? "text-emerald-400" : "text-rose-400"
                }`}>{selectedVehicle.trackerStatus}</span>
              </div>
              <div className="py-2 flex justify-between">
                <span className="text-neutral-400">Last GPS Address</span>
                <span className="text-white font-semibold text-right max-w-xs">{selectedVehicle.lastGpsLocation.address}</span>
              </div>
            </div>
            
            <button
              onClick={() => setSelectedVehicle(null)}
              className="w-full py-2 bg-neutral-900 border border-neutral-800 hover:bg-neutral-800 text-white font-bold rounded-xl text-xs"
            >
              Close Info File
            </button>
          </div>
        </div>
      )}

    </div>
  );
}
